package haxefolio;

import haxe.ui.Toolkit;
import haxe.ui.core.Component;
import js.html.DOMRect;
import morestd.Detachable;

/**
    Keeps a floating component - a popover, a tooltip - placed against the component it belongs to.
**/
class Anchoring
{
    /**
        Places `floating` against `anchor` per `placement` until the returned handle is detached,
        re-placing it whenever either changes size and when the breakpoint flips.

        `floating` has to be a child of `anchor` excluded from its layout (`includeInLayout = false`,
        as `NotificationCard.attach` does); adding and removing it is the caller's. The gap between
        them is `floating`'s CSS margin on the side facing `anchor`. While stretched, `floating`'s
        width (height for `Left`/`Right`) is set from `anchor`'s, and reset once it no longer is.
    **/
    public static function attach(floating:Component, anchor:Component, placement:ByWidth<AnchorPlacement>):Detachable
    {
        var binding:AnchorBinding = new AnchorBinding(floating, anchor);
        var breakpointBinding:Detachable = ResponsivityController.bind(placement, binding.setPlacement);

        return new Detachable(() -> {
            breakpointBinding.detach();
            binding.dispose();
        }, false);
    }
}

private class AnchorBinding
{
    private final floating:Component;
    private final anchor:Component;
    private final observer:Dynamic;

    private var placement:Null<AnchorPlacement> = null;

    public function new(floating:Component, anchor:Component)
    {
        this.floating = floating;
        this.anchor = anchor;

        observer = js.Syntax.code("new ResizeObserver({0})", onResized);
        observer.observe(floating.element);
        observer.observe(anchor.element);
    }

    public function setPlacement(placement:AnchorPlacement):Void
    {
        if (this.placement != null && this.placement.stretch == true)
        {
            if (isAcross(this.placement.side))
                floating.width = null;
            else
                floating.height = null;

            floating.invalidateComponentLayout(); // a null size alone doesn't make HaxeUI re-measure its own
        }

        this.placement = placement;
        place();
    }

    public function dispose():Void
    {
        observer.disconnect();
    }

    private function onResized(_:Array<Dynamic>):Void
    {
        place();
    }

    // measured from the DOM, which is what the observer reports on: HaxeUI's own size may lag behind it
    private function place():Void
    {
        if (placement == null)
            return;

        var anchorBounds:DOMRect = anchor.element.getBoundingClientRect();
        var floatingBounds:DOMRect = floating.element.getBoundingClientRect();
        var anchorWidth:Float = anchorBounds.width / Toolkit.scaleX;
        var anchorHeight:Float = anchorBounds.height / Toolkit.scaleY;
        var floatingWidth:Float = floatingBounds.width / Toolkit.scaleX;
        var floatingHeight:Float = floatingBounds.height / Toolkit.scaleY;

        if (placement.stretch == true)
        {
            if (isAcross(placement.side))
            {
                floating.width = anchorWidth;
                floatingWidth = anchorWidth;
            }
            else
            {
                floating.height = anchorHeight;
                floatingHeight = anchorHeight;
            }
        }

        switch placement.side
        {
            case Left:
                floating.left = -(floatingWidth + margin(floating.style?.marginRight));
                floating.top = aligned(anchorHeight, floatingHeight);
            case Right:
                floating.left = anchorWidth + margin(floating.style?.marginLeft);
                floating.top = aligned(anchorHeight, floatingHeight);
            case Above:
                floating.left = aligned(anchorWidth, floatingWidth);
                floating.top = -(floatingHeight + margin(floating.style?.marginBottom));
            case Below:
                floating.left = aligned(anchorWidth, floatingWidth);
                floating.top = anchorHeight + margin(floating.style?.marginTop);
        }
    }

    private function aligned(anchorLength:Float, floatingLength:Float):Float
    {
        return switch placement.align {
            case Start: 0;
            case Center: (anchorLength - floatingLength) / 2;
            case End: anchorLength - floatingLength;
        }
    }

    private static function margin(value:Null<Float>):Float
    {
        return value ?? 0.0;
    }

    // along the anchor's top or bottom edge
    private static function isAcross(side:AnchorSide):Bool
    {
        return side == Above || side == Below;
    }
}
