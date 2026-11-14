package haxefolio.structure;

import js.html.Element;

/**
    Fades out an edge of a native sideways scroller while it hides content. Attach it to the
    scroller's element once; it follows scrolling and the sizes of the scroller and its content.
**/
class SidewaysFade
{
    private final scroller:Element;
    private final fadePx:Int;

    public static function attach(scroller:Element, fadePx:Int = 24):Void
    {
        new SidewaysFade(scroller, fadePx);
    }

    /** Whether `scroller`'s content is wider than the scroller **/
    public static function isScrollable(scroller:Element):Bool
    {
        return scroller.scrollWidth > scroller.clientWidth + 1;
    }

    private function new(scroller:Element, fadePx:Int)
    {
        this.scroller = scroller;
        this.fadePx = fadePx;

        scroller.addEventListener("scroll", refresh);
        var observer:Dynamic = js.Syntax.code("new ResizeObserver({0})", (_:Array<Dynamic>) -> refresh());
        observer.observe(scroller);
        if (scroller.firstElementChild != null)
            observer.observe(scroller.firstElementChild);
    }

    private function refresh():Void
    {
        var hiddenLeft:Bool = scroller.scrollLeft > 1;
        var hiddenRight:Bool = scroller.scrollLeft + scroller.clientWidth < scroller.scrollWidth - 1;
        var start:String = hiddenLeft ? 'transparent 0, black ${fadePx}px' : "black 0";
        var end:String = hiddenRight ? 'black calc(100% - ${fadePx}px), transparent 100%' : "black 100%";
        var mask:String = 'linear-gradient(to right, $start, $end)';
        scroller.style.setProperty("mask-image", mask);
        scroller.style.setProperty("-webkit-mask-image", mask);
    }
}
