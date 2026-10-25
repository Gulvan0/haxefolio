package haxefolio.structure;

import haxe.ui.containers.ScrollView;
import haxe.ui.core.Component;
import haxe.ui.constants.ScrollMode;
import js.Browser;
import js.html.Element;
import js.html.StyleElement;

/*
    The shared treatment for every scrolling area the framework builds (a `Scroll` region, and
    every page of a tab region): vertical scrolling only, the scrollbar gutter reserved at all
    times so usable width never changes, and scrolling that reaches an end stopping there.

    Built on HaxeUI's `ScrollView` in native scroll mode, because both guarantees are properties
    of the browser's own scroller: `overscroll-behavior: contain` stops scroll chaining for wheel,
    drag and touch momentum alike, and an always-shown, styled scrollbar keeps its lane whether or
    not the content overflows. HaxeUI's own scrollbars can do neither. The containment applies only
    while the content actually overflows: an area with nothing to scroll lets the wheel through to
    the page behind it.

    With a fine pointer, the scrollbar is a thin permanent lane (10px, 6px thumb) drawn with
    `::-webkit-scrollbar`, which HaxeUI's stylesheets cannot reach - so its rules are injected once
    as a plain document stylesheet, keyed on a marker class this component puts on its own DOM
    element. Firefox has no equivalent of those pseudo-elements: it gets a thin scrollbar with the
    same colours, whose exact width is the browser's. With a coarse pointer the browser's own
    scrollbar is kept: on phones and tablets it overlays the content and takes no width.

    The contents are sized explicitly to the area's width less the lane's measured width. As a
    percentage, HaxeUI would resolve them against the whole width, lane included, and take a
    further native scrollbar's width off them whenever they overflow - so the usable width would
    change when the content grows past the area.

    HaxeUI's HTML5 backend marks every component `touch-action: none` unless its own scrollers are
    native, which stops the browser from panning this area by touch; the same stylesheet restores
    vertical panning for the area and everything inside it. Components that need raw touch input
    (the board) set `touch-action` inline, which still wins.
*/
class ScrollArea extends ScrollView
{
    private static inline var MARKER_CLASS:String = "haxefolio-scroll-area";

    private static var styleInjected:Bool = false;

    public function new(content:Component)
    {
        super();

        injectStyleOnce();

        this.percentWidth = 100;
        this.scrollMode = NATIVE;
        this.percentContentWidth = 100; // until the lane can be measured
        this.addClass("haxefolio-scroll-area");
        this.addComponent(content);

        this.element.classList.add(MARKER_CLASS);
    }

    /*
        HaxeUI applies its own `overflow: auto` to a native scroller when it becomes ready, so the
        overrides must come after that rather than in the constructor.
    */
    private override function onReady():Void
    {
        super.onReady();

        var nativeElement:Element = this.element;
        nativeElement.style.overflowX = "hidden";
        nativeElement.style.overflowY = "scroll";
        fitContentsToLane();

        var observer:Dynamic = js.Syntax.code("new ResizeObserver({0})", (_:Array<Dynamic>) -> updateContainment());
        observer.observe(nativeElement);
        observer.observe(contents.element);
        updateContainment();
    }

    private function updateContainment():Void
    {
        var nativeElement:Element = this.element;
        var overflows:Bool = nativeElement.scrollHeight > nativeElement.clientHeight;
        (cast nativeElement.style : Dynamic).overscrollBehavior = overflows ? "contain" : "auto";
    }

    private override function onResized():Void
    {
        super.onResized();
        fitContentsToLane();
    }

    private function fitContentsToLane():Void
    {
        if (contents == null || this.componentWidth <= 0)
            return;

        var laneWidth:Float = this.element.offsetWidth - this.element.clientWidth;
        var usableWidth:Float = this.componentWidth - laneWidth;
        if (this.percentContentWidth != null || this.contentWidth != usableWidth)
            this.contentWidth = usableWidth;
    }

    private static function injectStyleOnce():Void
    {
        if (styleInjected)
            return;

        styleInjected = true;

        var style:StyleElement = Browser.document.createStyleElement();
        style.textContent = '
            #haxeui-container .$MARKER_CLASS, #haxeui-container .$MARKER_CLASS .haxeui-component { touch-action: pan-y; }
            @media not (pointer: coarse) {
                .$MARKER_CLASS::-webkit-scrollbar { width: 10px; background: transparent; }
                .$MARKER_CLASS::-webkit-scrollbar-track { background: transparent; }
                .$MARKER_CLASS::-webkit-scrollbar-thumb { background-color: #cccdd1; background-clip: padding-box; border: 2px solid transparent; border-radius: 6px; min-height: 32px; }
                .$MARKER_CLASS::-webkit-scrollbar-thumb:hover { background-color: #b3b3b6; }
                .$MARKER_CLASS::-webkit-scrollbar-thumb:active { background-color: #90929a; }
                @supports not selector(::-webkit-scrollbar) { .$MARKER_CLASS { scrollbar-width: thin; scrollbar-color: #cccdd1 transparent; } }
            }
        ';
        Browser.document.head.appendChild(style);
    }
}
