package haxefolio.graphics;

import haxe.ui.backend.html5.svg.SVGBuilder;
import haxe.ui.backend.html5.svg.SVGPathBuilder;
import haxe.ui.backend.html5.svg.SVGTextBuilder;
import haxe.ui.backend.html5.svg.SVGImageBuilder;
import haxe.ui.core.Component;
import haxe.ui.styles.Style;

/**
    A HaxeUI-tree-compatible component wrapping a single raw `<svg>` element with a fixed
    `viewBox`. Exposes typed builders (`path`/`text`/`image`) that return live handles usable for
    later attribute updates - restyling a shape means writing to its own handle, never recreating
    it.

    The surface always scales to whatever size its container gives it: it takes 100% of its
    container's width, and derives its height from `viewBoxWidth`/`viewBoxHeight`'s aspect ratio.
    Nothing drawn on it is ever recomputed on resize - the fixed `viewBox` coordinate system is
    all any caller ever draws in, and the browser's own scaling does the rest.
**/
class SvgSurface extends Component
{
    private var svg:SVGBuilder;
    private var aspectRatio:Float;

    public function new(viewBoxWidth:Float, viewBoxHeight:Float)
    {
        super();

        this.aspectRatio = viewBoxWidth / viewBoxHeight;
        this.percentWidth = 100;

        svg = new SVGBuilder();
        svg.element.setAttribute("viewBox", '0 0 $viewBoxWidth $viewBoxHeight');
        svg.element.style.display = "block";
        svg.element.style.width = "100%";
        svg.element.style.height = "100%";

        this.element.style.setProperty("aspect-ratio", '$viewBoxWidth / $viewBoxHeight');
        this.element.appendChild(svg.element);
    }

    /*
        haxeui-html5's ComponentImpl.handleSize only ever applies a size at all when both `width`
        and `height` are non-null - a component sized purely by `percentWidth`, with no paired
        `percentHeight`/explicit `height`, never gets its width applied either. Deriving `height`
        from the resolved `width` here, rather than depending on CSS `aspect-ratio` alone, is what
        makes `percentWidth` actually take effect; the `aspect-ratio` declaration above stays as a
        redundant safety net.
    */
    private override function handleSize(width:Null<Float>, height:Null<Float>, style:Style):Void
    {
        if (width != null && width > 0 && (height == null || height <= 0))
            height = width / aspectRatio;

        super.handleSize(width, height, style);

        if (width != null && width > 0 && height != null && this.height != height)
            this.height = height;
    }

    /**
        Removes every shape drawn on this surface so far, invalidating any handle returned by
        `path`/`text`/`image` up to this point.
    **/
    public function clear():Void
    {
        svg.clear();
    }

    /**
        Draws a new path with its pen positioned at `(x, y)`, in `viewBox` units. Returns a live
        handle: call `lineTo`/`close`/`stroke`/`fill` on it to build and style the shape, and keep
        the handle to restyle it later via the same calls.
    **/
    public function svgPath(x:Float, y:Float):SVGPathBuilder
    {
        return svg.path(x, y);
    }

    /**
        Draws a text label at `(x, y)`, in `viewBox` units. Returns a live handle for later
        restyling.
    **/
    public function svgText(value:String, x:Float, y:Float):SVGTextBuilder
    {
        return svg.text(value, x, y);
    }

    /**
        Draws an image at `(x, y)`, sized `width`x`height`, all in `viewBox` units. Returns a live
        handle for later restyling.
    **/
    public function svgImage(href:String, x:Float, y:Float, width:Float, height:Float):SVGImageBuilder
    {
        return svg.image(href, x, y, width, height);
    }
}
