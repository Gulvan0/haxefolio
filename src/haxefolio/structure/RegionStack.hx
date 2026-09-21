package haxefolio.structure;

import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.appearance.AppearanceContext;
import morestd.Detachable;

/**
    A frame of fixed height holding an ordered list of regions, one of which - the `Scroll` region, or
    the pages of a `Tabs` one - is the scrolling area and every other has a declared, constant height
    (a `Tabs` region contributes its strip as a fixed region and the pages as the scrolling area).

    The frame's height is given, never measured, and so is every region's; the scrolling area
    gets `scrollHeight = frameHeight - sum of fixed heights`. It is the only region that ever
    resizes: changing `frameHeight` (a viewport resize) or the breakpoint state (a fixed region's
    `ByWidth` height differing between the two) changes exactly that one number. Nothing is ever
    asked how tall it is, so adding content to a region never moves another.

    A stack with no scrolling area is legal (every region fixed); one with more than one is not.
    If the fixed regions alone exceed the frame, the scrolling area is squeezed to zero rather than
    overflowing - a design error to correct, not a case to accommodate.

    A `Header`, `Actions` or `Tabs` region takes its height from the `AppearanceContext` in effect when
    the stack is built (the `headerHeight`/`actionBarHeight`/`tabStripHeight` token) unless it names
    one of its own.

    Call `dispose()` once the stack is done with, to detach its breakpoint subscriptions.
**/
class RegionStack extends VBox
{
    private final fixedHeights:Array<Int> = [];
    private final bindings:Array<Detachable> = [];
    private final dismiss:Null<Void->Void>;
    private final idPrefix:Null<String>;
    private var titledTabsRegion:Bool = false;
    private var initialTabTitle:Null<String>;
    private var headerBaseTitle:String = "";
    private var scrollingComponent:Null<Component>;
    private var headerBar:Null<HeaderBar>;

    /**
        The height of the whole stack. Assigning it recomputes the scrolling area's height and
        nothing else.
    **/
    public var frameHeight(default, set):Float = 0;

    /**
        `dismiss` is what a `Header` region's close control calls; without it (nothing to dismiss)
        there is no close control. `idPrefix`, if given, names the parts for a stylesheet: the
        regions get the ids `<idPrefix>-header`, `-tabs` (the strip), `-actions` and `-scroll` (the
        scrolling area, the pages' slot for a `Tabs` region), the close control `-close`.
    **/
    public function new(regions:Array<Region>, frameHeight:Float, ?dismiss:Void->Void, ?idPrefix:String)
    {
        super();

        this.dismiss = dismiss;
        this.idPrefix = idPrefix;

        this.percentWidth = 100;
        this.verticalSpacing = 0;
        this.addClass("haxefolio-region-stack");

        for (region in regions)
            addRegion(region);

        if (titledTabsRegion)
        {
            if (headerBar == null)
                throw "RegionStack: a Tabs region with titled pages needs a Header region to show them.";

            applyTabTitle(initialTabTitle);
        }

        this.frameHeight = frameHeight;
    }

    /**
        The height currently left for the scrolling area, or `0` if the stack has none.
    **/
    public function scrollHeight():Float
    {
        var fixedTotal:Int = 0;
        for (height in fixedHeights)
            fixedTotal += height;

        return Math.max(0, frameHeight - fixedTotal);
    }

    public function dispose():Void
    {
        for (binding in bindings)
            binding.detach();
    }

    private function addRegion(region:Region):Void
    {
        switch region
        {
            case Header(title, height, hideClose):
                var closeHandler:Null<Void->Void> = hideClose == true ? null : dismiss;
                var closeButtonId:Null<String> = idPrefix == null ? null : '$idPrefix-close';
                headerBar = new HeaderBar(title, closeHandler, closeButtonId);
                headerBaseTitle = title;
                addFixedRegion(height ?? AppearanceContext.current.geometry.headerHeight, headerBar, "haxefolio-region-header", "header");

            case Actions(bar, height):
                addFixedRegion(height ?? AppearanceContext.current.geometry.actionBarHeight, bar, "haxefolio-region-actions", "actions");

            case Custom(height, content):
                addFixedRegion(height, content, "haxefolio-region-custom");

            case Scroll(content):
                claimScrollingArea();

                var scrollArea:ScrollArea = new ScrollArea(content);
                addScrollingComponent(scrollArea);

            case Tabs(role, pages, stripHeight, onSelect):
                addTabsRegion(role, pages, stripHeight, onSelect);
        }
    }

    private function claimScrollingArea():Void
    {
        if (scrollingComponent != null)
            throw "RegionStack: at most one scrolling area (a Scroll or a Tabs region) is allowed.";
    }

    private function addScrollingComponent(component:Component):Void
    {
        scrollingComponent = component;

        if (idPrefix != null)
            component.id = '$idPrefix-scroll';

        this.addComponent(component);
    }

    private function addTabsRegion(role:TabRole, pages:Array<TabPage>, ?stripHeight:ByWidth<Int>, ?onSelect:Int->Void):Void
    {
        claimScrollingArea();

        if (pages.length == 0)
            throw "RegionStack: a Tabs region needs at least one page.";

        var pageTitles:Array<Null<String>> = [for (page in pages) page.title];
        var hasTitles:Bool = [for (title in pageTitles) if (title != null) title].length > 0;

        if (hasTitles && role == Navigate)
            throw "RegionStack: only the pages of a Choose region may have titles - a Navigate region's frame title is fixed.";

        titledTabsRegion = hasTitles;

        var pageAreas:Map<Int, Component> = [];
        for (i in 0...pages.length)
        {
            var pageArea:ScrollArea = new ScrollArea(pages[i].content);
            pageArea.percentHeight = 100;
            pageAreas[i] = pageArea;
        }

        var pageSlot:SwapSlot<Int> = new SwapSlot(pageAreas, 0, 0);

        var strip:TabStrip = new TabStrip(role, pages, 0, index -> {
            pageSlot.active = index;

            if (hasTitles)
                applyTabTitle(pageTitles[index]);

            if (onSelect != null)
                onSelect(index);
        });
        bindings.push(new Detachable(strip.dispose, false));

        addFixedRegion(stripHeight ?? AppearanceContext.current.geometry.tabStripHeight, strip, "haxefolio-region-tabs", "tabs");
        addScrollingComponent(pageSlot);

        initialTabTitle = pageTitles[0];
    }

    // A page without a title of its own shows the Header region's
    private function applyTabTitle(title:Null<String>):Void
    {
        if (headerBar != null)
            headerBar.title = title ?? headerBaseTitle;
    }

    private function addFixedRegion(height:ByWidth<Int>, content:Component, styleClass:String, ?idSuffix:String):Void
    {
        var slot:Box = new Box();
        slot.percentWidth = 100;
        slot.clip = true;
        slot.addClass(styleClass);

        if (idPrefix != null && idSuffix != null)
            slot.id = '$idPrefix-$idSuffix';

        slot.addComponent(content);
        this.addComponent(slot);

        var fixedIndex:Int = fixedHeights.length;
        fixedHeights.push(0);
        bindings.push(ResponsivityController.bind(height, resolved -> {
            fixedHeights[fixedIndex] = resolved;
            slot.height = resolved;
            applyScrollHeight();
        }));
    }

    private function applyScrollHeight():Void
    {
        if (scrollingComponent == null)
            return;

        // HaxeUI ignores an assignment of 0 to `height`, so an exhausted frame hides the area instead
        var remaining:Float = scrollHeight();
        scrollingComponent.hidden = remaining <= 0;

        if (remaining > 0)
            scrollingComponent.height = remaining;
    }

    private function set_frameHeight(value:Float):Float
    {
        frameHeight = value;
        this.height = value;
        applyScrollHeight();
        return value;
    }
}
