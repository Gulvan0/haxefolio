package haxefolio.structure;

import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.core.Component;
import haxefolio.appearance.AppearanceContext;
import morestd.Detachable;

/**
    The fixed row of tab labels a `Tabs` region holds, in the drawing of its `TabRole`: `Navigate`
    is flush, underlined tabs at their natural width; `Choose` is a segmented control on a recessed
    track, equal-width. It only owns the labels and the selection - the pages are the region's.

    A tab is one line and is not truncated (there is no ellipsis), so the labels of a strip must fit
    it; `Choose` divides the strip's width evenly, so its captions have to fit the narrowest share.

    A tab whose page has an `ErrorMarker` reserves a small marker lane for its whole life, so the
    marker appearing never moves a tab or its neighbours. Call `dispose()` once the strip is done
    with, to release the marker subscriptions.
**/
class TabStrip extends HBox
{
    private static inline var TAB_INNER_PADDING:Int = 12;
    private static inline var CHOOSE_TRACK_HEIGHT:Int = 32;

    private final role:TabRole;
    private final selectionHandler:Int->Void;
    private final tabs:Array<Box> = [];
    private final tabLabels:Array<Label> = [];
    private final markerBindings:Array<Detachable> = [];

    /**
        The selected tab. Assigning it only renders the selection - the change handler is for the
        user's own clicks.
    **/
    public var selectedIndex(default, set):Int = -1;

    /**
        `onSelected` receives the index of a tab the user clicked (not the one already selected).
    **/
    public function new(role:TabRole, pages:Array<TabPage>, selectedIndex:Int, onSelected:Int->Void)
    {
        super();

        this.role = role;
        this.selectionHandler = onSelected;

        this.percentWidth = 100;
        this.percentHeight = 100;
        this.addClass("haxefolio-tab-strip");

        var tabContainer:Component = this;

        switch role
        {
            case Navigate:
                this.paddingLeft = Std.int(Math.max(0, AppearanceContext.current.geometry.padding - TAB_INNER_PADDING));
                this.addClass("haxefolio-tab-strip-navigate");

            case Choose:
                this.paddingLeft = AppearanceContext.current.geometry.padding;
                this.paddingRight = AppearanceContext.current.geometry.padding;
                this.addClass("haxefolio-tab-strip-choose");

                var track:HBox = new HBox();
                track.percentWidth = 100;
                track.height = CHOOSE_TRACK_HEIGHT;
                track.verticalAlign = "center";
                track.addClass("haxefolio-tab-track");
                this.addComponent(track);
                tabContainer = track;
        }

        for (i in 0...pages.length)
        {
            var tab:Box = buildTab(i, pages[i], pages.length);
            tabs.push(tab);
            tabContainer.addComponent(tab);
        }

        this.selectedIndex = selectedIndex;
    }

    /**
        Releases the subscriptions to the pages' error markers.
    **/
    public function dispose():Void
    {
        for (binding in markerBindings)
            binding.detach();
    }

    private function buildTab(index:Int, page:TabPage, count:Int):Box
    {
        var tab:Box = new Box();
        tab.percentHeight = 100;
        tab.paddingLeft = TAB_INNER_PADDING;
        tab.paddingRight = TAB_INNER_PADDING;
        tab.addClass("haxefolio-tab");
        tab.addClass(role == Navigate ? "haxefolio-tab-navigate" : "haxefolio-tab-choose");
        tab.onClick = _ -> onTabClicked(index);

        if (role == Choose)
            tab.percentWidth = 100 / count;

        var content:HBox = new HBox();
        content.horizontalAlign = "center";
        content.verticalAlign = "center";
        content.horizontalSpacing = 6;
        content.addClass("haxefolio-tab-content");
        tab.addComponent(content);

        if (page.icon != null)
        {
            var icon:Image = new Image();
            icon.resource = page.icon;
            icon.verticalAlign = "center";
            icon.addClass("haxefolio-tab-icon");
            content.addComponent(icon);
        }

        var label:Label = new Label();
        label.text = page.label;
        label.verticalAlign = "center";
        label.addClass("haxefolio-tab-label");
        content.addComponent(label);
        tabLabels.push(label);

        if (page.errorMarker != null)
        {
            var marker:Box = new Box();
            marker.width = 6;
            marker.height = 6;
            marker.verticalAlign = "center";
            marker.addClass("haxefolio-tab-marker");
            content.addComponent(marker);

            applyMarker(marker, page.errorMarker.active);
            markerBindings.push(page.errorMarker.onChange(active -> applyMarker(marker, active)));
        }

        return tab;
    }

    private function onTabClicked(index:Int):Void
    {
        if (index == selectedIndex)
            return;

        selectedIndex = index;
        selectionHandler(index);
    }

    private function applyMarker(marker:Box, active:Bool):Void
    {
        if (active)
            marker.addClass("haxefolio-tab-marker-active");
        else
            marker.removeClass("haxefolio-tab-marker-active");
    }

    private function set_selectedIndex(value:Int):Int
    {
        if (value < 0 || value >= tabs.length)
            throw 'TabStrip: no tab at index $value';

        selectedIndex = value;

        var roleSelectedClass:String = role == Navigate ? "haxefolio-tab-navigate-selected" : "haxefolio-tab-choose-selected";

        for (i in 0...tabs.length)
        {
            if (i == value)
            {
                tabs[i].addClass("haxefolio-tab-selected");
                tabs[i].addClass(roleSelectedClass);
                tabLabels[i].addClass("haxefolio-tab-label-selected");
            }
            else
            {
                tabs[i].removeClass("haxefolio-tab-selected");
                tabs[i].removeClass(roleSelectedClass);
                tabLabels[i].removeClass("haxefolio-tab-label-selected");
            }
        }

        return value;
    }
}
