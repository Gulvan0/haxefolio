package haxefolio.appearance;

/**
    A partial `Appearance`, as supplied by a host: for the whole theme (`HaxeFolioConfig.appearance`)
    or, later, for a single overlay. Anything left out keeps the value it would otherwise have.
**/
typedef AppearanceOverrides = {
    ?geometry:PartialGeometryTokens,
    ?emphasis:EmphasisStyle,

    /**
        Style class the framework puts on the overlay root, for a colour variant shared by several
        overlays. Only meaningful for a per-overlay override; ignored theme-wide.
    **/
    ?styleClass:String
}
