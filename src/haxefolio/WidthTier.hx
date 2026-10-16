package haxefolio;

/**
    A host-defined viewport width range of the tier scale `scale`, from `minWidth` up to the next
    tier's `minWidth` in that scale (see `HaxeFolioConfig.widthTiers`). `name` is what
    `ResponsivityController.currentTier(scale)` reports and what the `haxefolio-tier-<scale>-<name>`
    root class carries.
**/
typedef WidthTier =
{
    scale:String,
    name:String,
    minWidth:Int,

    /** Narrows the tier further by the viewport's width and height: while false, the tier is passed over as if `minWidth` weren't reached **/
    ?fits:(width:Float, height:Float)->Bool
}
