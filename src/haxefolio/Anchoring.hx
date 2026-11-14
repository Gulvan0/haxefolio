package haxefolio;

import haxe.ui.Toolkit;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import js.Browser;
import js.html.DOMRect;
import js.html.Event;
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
    public static function attach(floating:Component, anchor:Component, placement:ByMenuLayout<AnchorPlacement>):Detachable
    {
        var binding:AnchorBinding = new AnchorBinding(floating, anchor);
        var breakpointBinding:Detachable = ResponsivityController.bind(placement, binding.setPlacement);

        return new Detachable(() -> {
            breakpointBinding.detach();
            binding.dispose();
        }, false);
    }

    /**
        Like `attach`, for an anchor whose ancestors clip or scroll: `floating` is added to the screen
        as a root of its own, over the page, and placed against `anchor`'s on-screen bounds, following
        it as any of its ancestors scrolls. `floating` must not have a parent; detaching the handle
        removes it from the screen without disposing it.

        A floating component that doesn't fit the viewport on `placement`'s side moves to the
        opposite one when more of it fits there, and is shifted along the side to stay on screen.
    **/
    public static function attachOnScreen(floating:Component, anchor:Component, placement:ByMenuLayout<AnchorPlacement>):Detachable
    {
        Screen.instance.addComponent(floating);
        var binding:ScreenAnchorBinding = new ScreenAnchorBinding(floating, anchor);
        var breakpointBinding:Detachable = ResponsivityController.bind(placement, binding.setPlacement);

        return new Detachable(() -> {
            breakpointBinding.detach();
            binding.dispose();
            Screen.instance.removeComponent(floating, false);
        }, false);
    }
}

private class ScreenAnchorBinding
{
    private static inline final VIEWPORT_MARGIN:Float = 8;

    private final floating:Component;
    private final anchor:Component;
    private final observer:Dynamic;
    private final scrollOptions:Dynamic = {capture: true, passive: true};

    private var placement:Null<AnchorPlacement> = null;

    public function new(floating:Component, anchor:Component)
    {
        this.floating = floating;
        this.anchor = anchor;

        observer = js.Syntax.code("new ResizeObserver({0})", onResized);
        observer.observe(floating.element);
        observer.observe(anchor.element);
        Browser.document.addEventListener("scroll", onMoved, scrollOptions);
        Browser.window.addEventListener("resize", onMoved);
    }

    public function setPlacement(placement:AnchorPlacement):Void
    {
        if (this.placement != null && this.placement.stretch == true)
        {
            if (isAcross(this.placement.side))
                floating.width = null;
            else
                floating.height = null;

            floating.invalidateComponentLayout();
        }

        this.placement = placement;
        place();
    }

    public function dispose():Void
    {
        observer.disconnect();
        Browser.document.removeEventListener("scroll", onMoved, scrollOptions);
        Browser.window.removeEventListener("resize", onMoved);
    }

    private function onResized(_:Array<Dynamic>):Void
    {
        place();
    }

    private function onMoved(_:Event):Void
    {
        place();
    }

    // in viewport coordinates, the space screen roots are laid out in
    private function place():Void
    {
        if (placement == null || !anchor.element.isConnected)
            return;

        var anchorBounds:DOMRect = anchor.element.getBoundingClientRect();
        var floatingBounds:DOMRect = floating.element.getBoundingClientRect();
        var anchorLeft:Float = anchorBounds.left / Toolkit.scaleX;
        var anchorTop:Float = anchorBounds.top / Toolkit.scaleY;
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

        var viewportWidth:Float = Viewport.width();
        var viewportHeight:Float = Viewport.height();

        switch placement.side
        {
            case Above | Below:
                var gapAbove:Float = margin(floating.style?.marginBottom);
                var gapBelow:Float = margin(floating.style?.marginTop);
                var roomAbove:Float = anchorTop - gapAbove - VIEWPORT_MARGIN;
                var roomBelow:Float = viewportHeight - (anchorTop + anchorHeight) - gapBelow - VIEWPORT_MARGIN;
                var below:Bool = placement.side == Below ? prefersOwnSide(floatingHeight, roomBelow, roomAbove) : !prefersOwnSide(floatingHeight, roomAbove, roomBelow);
                floating.top = below ? anchorTop + anchorHeight + gapBelow : anchorTop - gapAbove - floatingHeight;
                floating.left = shifted(anchorLeft + aligned(anchorWidth, floatingWidth), floatingWidth, viewportWidth);
            case Left | Right:
                var gapLeft:Float = margin(floating.style?.marginRight);
                var gapRight:Float = margin(floating.style?.marginLeft);
                var roomLeft:Float = anchorLeft - gapLeft - VIEWPORT_MARGIN;
                var roomRight:Float = viewportWidth - (anchorLeft + anchorWidth) - gapRight - VIEWPORT_MARGIN;
                var right:Bool = placement.side == Right ? prefersOwnSide(floatingWidth, roomRight, roomLeft) : !prefersOwnSide(floatingWidth, roomLeft, roomRight);
                floating.left = right ? anchorLeft + anchorWidth + gapRight : anchorLeft - gapLeft - floatingWidth;
                floating.top = shifted(anchorTop + aligned(anchorHeight, floatingHeight), floatingHeight, viewportHeight);
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

    // stays on the requested side if it fits there, or if the opposite side has no more room
    private static function prefersOwnSide(length:Float, ownRoom:Float, oppositeRoom:Float):Bool
    {
        return length <= ownRoom || ownRoom >= oppositeRoom;
    }

    // within the viewport's margins where it fits, its start edge in view where it doesn't
    private static function shifted(start:Float, length:Float, viewportLength:Float):Float
    {
        return Math.max(VIEWPORT_MARGIN, Math.min(start, viewportLength - VIEWPORT_MARGIN - length));
    }

    private static function margin(value:Null<Float>):Float
    {
        return value ?? 0.0;
    }

    private static function isAcross(side:AnchorSide):Bool
    {
        return side == Above || side == Below;
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
