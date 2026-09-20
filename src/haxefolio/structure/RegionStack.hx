package haxefolio.structure;

import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import morestd.Detachable;

/**
    A frame of fixed height holding an ordered list of regions, one of which - the `Scroll` region -
    is the scrolling area and every other has a declared, constant height.

    The frame's height is given, never measured, and so is every region's; the scrolling area
    gets `scrollHeight = frameHeight - sum of fixed heights`. It is the only region that ever
    resizes: changing `frameHeight` (a viewport resize) or the breakpoint state (a fixed region's
    `ByWidth` height differing between the two) changes exactly that one number. Nothing is ever
    asked how tall it is, so adding content to a region never moves another.

    A stack with no `Scroll` region is legal (every region fixed); one with more than one is not.
    If the fixed regions alone exceed the frame, the scrolling area is squeezed to zero rather than
    overflowing - a design error to correct, not a case to accommodate.

    Call `dispose()` once the stack is done with, to detach its breakpoint subscriptions.
**/
class RegionStack extends VBox
{
    private final fixedHeights:Array<Int> = [];
    private final bindings:Array<Detachable> = [];
    private var scrollArea:Null<ScrollArea>;

    /**
        The height of the whole stack. Assigning it recomputes the scrolling area's height and
        nothing else.
    **/
    public var frameHeight(default, set):Float = 0;

    public function new(regions:Array<Region>, frameHeight:Float)
    {
        super();

        this.percentWidth = 100;
        this.verticalSpacing = 0;
        this.addClass("haxefolio-region-stack");

        for (region in regions)
            addRegion(region);

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
            case Custom(height, content):
                var slot:Box = new Box();
                slot.percentWidth = 100;
                slot.clip = true;
                slot.addClass("haxefolio-region-custom");
                slot.addComponent(content);
                this.addComponent(slot);

                var fixedIndex:Int = fixedHeights.length;
                fixedHeights.push(0);
                bindings.push(ResponsivityController.bind(height, resolved -> {
                    fixedHeights[fixedIndex] = resolved;
                    slot.height = resolved;
                    applyScrollHeight();
                }));

            case Scroll(content):
                if (scrollArea != null)
                    throw "RegionStack: at most one Scroll region is allowed.";

                scrollArea = new ScrollArea(content);
                this.addComponent(scrollArea);
        }
    }

    private function applyScrollHeight():Void
    {
        if (scrollArea == null)
            return;

        // HaxeUI ignores an assignment of 0 to `height`, so an exhausted frame hides the area instead
        var remaining:Float = scrollHeight();
        scrollArea.hidden = remaining <= 0;

        if (remaining > 0)
            scrollArea.height = remaining;
    }

    private function set_frameHeight(value:Float):Float
    {
        frameHeight = value;
        this.height = value;
        applyScrollHeight();
        return value;
    }
}
