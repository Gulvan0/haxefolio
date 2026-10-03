package haxefolio.graphics;

import haxe.ui.backend.html5.svg.SVGBuilder;
import haxe.ui.backend.html5.svg.SVGPathBuilder;
import haxe.ui.backend.html5.svg.SVGTextBuilder;
import haxe.ui.backend.html5.svg.SVGImageBuilder;
import haxe.ui.backend.html5.svg.SVGCircleBuilder;
import js.Browser;
import js.html.svg.GElement;

/**
    A group of shapes inside an `SvgSurface` (a `<g>` element), created by `SvgSurface.addLayer`.
    Layers paint in the order they were added, each above the previous ones; whatever a layer
    draws stays inside it, so clearing and redrawing one layer never touches the others or changes
    the stacking. Coordinates are the surface's `viewBox` units.
**/
class SvgLayer
{
    private final group:SVGBuilder;

    /**
        The layer's own `<g>` element, e.g. for setting a group-wide `opacity`.
    **/
    public var element(get, never):GElement;

    private function get_element():GElement
    {
        return cast group.element;
    }

    @:allow(haxefolio.graphics.SvgSurface)
    private function new()
    {
        group = new SVGBuilder(cast Browser.document.createElementNS("http://www.w3.org/2000/svg", "g"));
    }

    /**
        Removes every shape drawn on this layer so far, invalidating any handle returned by its
        builders up to this point. Other layers are unaffected.
    **/
    public function clear():Void
    {
        group.clear();
    }

    /**
        Same as `SvgSurface.svgPath`, drawn on this layer.
    **/
    public function svgPath(x:Float, y:Float):SVGPathBuilder
    {
        return group.path(x, y);
    }

    /**
        Same as `SvgSurface.svgText`, drawn on this layer.
    **/
    public function svgText(value:String, x:Float, y:Float):SVGTextBuilder
    {
        return group.text(value, x, y);
    }

    /**
        Same as `SvgSurface.svgImage`, drawn on this layer.
    **/
    public function svgImage(href:String, x:Float, y:Float, width:Float, height:Float):SVGImageBuilder
    {
        return group.image(href, x, y, width, height);
    }

    /**
        Same as `SvgSurface.svgCircle`, drawn on this layer.
    **/
    public function svgCircle(x:Float, y:Float, r:Float):SVGCircleBuilder
    {
        return group.circle(x, y, r);
    }
}
