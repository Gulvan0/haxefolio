package haxefolio.graphics;

import haxe.ui.backend.html5.svg.SVGBuilder;
import haxe.ui.backend.html5.svg.SVGPathBuilder;
import haxe.ui.backend.html5.svg.SVGTextBuilder;
import haxe.ui.backend.html5.svg.SVGImageBuilder;
import haxe.ui.backend.html5.svg.SVGCircleBuilder;
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
    private var viewBoxWidth:Float;
    private var viewBoxHeight:Float;

    public function new(viewBoxWidth:Float, viewBoxHeight:Float)
    {
        super();

        this.viewBoxWidth = viewBoxWidth;
        this.viewBoxHeight = viewBoxHeight;
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
        handleSize only applies a size when both width and height are non-null, so deriving height
        from width is what makes percentWidth take effect at all. Must recompute height on every
        call rather than only when it comes in null: the framework re-passes whatever height this
        override assigned last time, so guarding on "already have one" would pin the surface's
        height at its first-render value, silently capping how far it can grow on later resizes.
    */
    private override function handleSize(width:Null<Float>, height:Null<Float>, style:Style):Void
    {
        if (width != null && width > 0)
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

    /**
        Draws a circle centered at `(x, y)` with radius `r`, all in `viewBox` units. Returns a live
        handle for later restyling.
    **/
    public function svgCircle(x:Float, y:Float, r:Float):SVGCircleBuilder
    {
        return svg.circle(x, y, r);
    }

    /**
        The inverse of `clientPointToViewBox`: converts a point in `viewBox` units into viewport
        coordinates (`clientX`/`clientY` space). Measured live, so it follows the surface's current
        on-screen position and size.
    **/
    public function viewBoxPointToClient(x:Float, y:Float):{x:Float, y:Float}
    {
        var rect = svg.element.getBoundingClientRect();
        return {
            x: rect.left + x * rect.width / viewBoxWidth,
            y: rect.top + y * rect.height / viewBoxHeight
        };
    }

    /**
        How many viewport pixels a single `viewBox` unit currently spans on screen.
    **/
    public function viewBoxUnitInPixels():Float
    {
        return svg.element.getBoundingClientRect().width / viewBoxWidth;
    }

    /**
        Converts a viewport point (a native DOM event's `clientX`/`clientY`) into `viewBox` units.
        Measured against the element's live `getBoundingClientRect()`, so it stays correct under
        any scrolling (including native scroll containers, which HaxeUI's own `screenLeft`/
        `screenTop` don't track) and CSS transforms. Don't feed it HaxeUI's `MouseEvent.screenX`/
        `screenY` - those are a different coordinate space.

        A point outside the surface still converts (negative, or past `viewBoxWidth`/
        `viewBoxHeight`) rather than clipping, e.g. so a dragged piece keeps following the cursor
        past the board's own edge.
    **/
    public function clientPointToViewBox(clientX:Float, clientY:Float):{x:Float, y:Float}
    {
        var rect = svg.element.getBoundingClientRect();
        return {
            x: (clientX - rect.left) * viewBoxWidth / rect.width,
            y: (clientY - rect.top) * viewBoxHeight / rect.height
        };
    }
}
