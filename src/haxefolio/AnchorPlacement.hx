package haxefolio;

/**
    Where `Anchoring` keeps a floating component. `stretch` makes it as long as the anchor's side it
    sits on (as wide for `Above`/`Below`, as tall for `Left`/`Right`), which makes `align` moot.
**/
typedef AnchorPlacement =
{
    side:AnchorSide,
    align:AnchorAlign,
    ?stretch:Bool
}
