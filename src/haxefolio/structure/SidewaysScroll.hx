package haxefolio.structure;

import js.Browser;
import js.html.Element;
import js.html.MouseEvent;
import js.html.PointerEvent;
import js.html.WheelEvent;

/**
    Mouse and edge treatment for a native scroller that scrolls sideways. Attach it to the scroller's
    element once. A vertical wheel turn scrolls the content sideways unless the scroller has vertical
    room to scroll, and never reaches the ancestors while there is something to scroll sideways. The
    content can be dragged with the left mouse button; a drag doesn't click the item it started on.
    An edge hiding content fades out (`SidewaysFade`, also usable alone). Touch scrolling stays native.
**/
class SidewaysScroll
{
    private static inline final DRAG_THRESHOLD_PX:Float = 4;
    private static inline final LINE_HEIGHT_PX:Float = 16;

    private final scroller:Element;

    private var pressX:Null<Float> = null;
    private var pressScrollLeft:Float = 0;
    private var dragging:Bool = false;
    private var suppressClick:Bool = false;

    public static function attach(scroller:Element, fadePx:Int = 24):Void
    {
        new SidewaysScroll(scroller, fadePx);
    }

    private function new(scroller:Element, fadePx:Int)
    {
        this.scroller = scroller;

        SidewaysFade.attach(scroller, fadePx);
        scroller.addEventListener("wheel", onWheel, {passive: false});
        scroller.addEventListener("pointerdown", onPointerDown);
        scroller.addEventListener("click", onClickCapture, true);
        js.Syntax.code("new ResizeObserver({0})", (_:Array<Dynamic>) -> refreshCursor()).observe(scroller);
    }

    private function onWheel(event:WheelEvent):Void
    {
        if (event.ctrlKey || !isScrollable() || Math.abs(event.deltaX) >= Math.abs(event.deltaY))
            return;

        if (scroller.scrollHeight > scroller.clientHeight + 1 && scroller.style.overflowY != "hidden")
            return;

        var factor:Float = event.deltaMode == WheelEvent.DOM_DELTA_LINE ? LINE_HEIGHT_PX : 1;
        scroller.scrollLeft = Std.int(scroller.scrollLeft + event.deltaY * factor);
        event.preventDefault();
    }

    private function onPointerDown(event:PointerEvent):Void
    {
        suppressClick = false;
        if (event.pointerType != "mouse" || event.button != 0 || !isScrollable() || isOverScrollbar(event))
            return;

        pressX = event.clientX;
        pressScrollLeft = scroller.scrollLeft;
        dragging = false;
        Browser.window.addEventListener("pointermove", onPointerMove);
        Browser.window.addEventListener("pointerup", onPointerUp);
    }

    private function onPointerMove(event:PointerEvent):Void
    {
        if (pressX == null)
            return;

        var shift:Float = event.clientX - pressX;
        if (!dragging && Math.abs(shift) > DRAG_THRESHOLD_PX)
        {
            dragging = true;
            scroller.style.cursor = "grabbing";
        }
        if (dragging)
            scroller.scrollLeft = Std.int(pressScrollLeft - shift);
    }

    private function onPointerUp(_:PointerEvent):Void
    {
        Browser.window.removeEventListener("pointermove", onPointerMove);
        Browser.window.removeEventListener("pointerup", onPointerUp);
        suppressClick = dragging;
        dragging = false;
        pressX = null;
        refreshCursor();
    }

    private function onClickCapture(event:MouseEvent):Void
    {
        if (!suppressClick)
            return;

        suppressClick = false;
        event.stopPropagation();
        event.preventDefault();
    }

    private function isScrollable():Bool
    {
        return SidewaysFade.isScrollable(scroller);
    }

    private function isOverScrollbar(event:PointerEvent):Bool
    {
        return event.clientY > scroller.getBoundingClientRect().top + scroller.clientHeight;
    }

    private function refreshCursor():Void
    {
        if (!dragging)
            scroller.style.cursor = isScrollable() ? "grab" : "";
    }
}
