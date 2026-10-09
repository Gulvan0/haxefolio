package haxefolio;

/**
    A CSS `box-shadow`, applied with `ElementShadow`. Offsets, `blur` and `spread` are in pixels;
    `color` is `0xRRGGBB`, `opacity` from 0 to 1.
**/
typedef Shadow =
{
    offsetX:Float,
    offsetY:Float,
    blur:Float,
    ?spread:Float,
    color:Int,
    opacity:Float
}
