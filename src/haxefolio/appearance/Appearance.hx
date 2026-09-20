package haxefolio.appearance;

/**
    The code-side half of the framework's theming: what the framework computes with, and semantic
    choices components must agree on. Colour and typography are deliberately not here - they stay
    in stylesheets, where the cascade is the right mechanism for them.
**/
typedef Appearance = {
    /**
        The tokens the framework's height arithmetic reads.
    **/
    geometry:GeometryTokens,

    /**
        Which treatment means "primary" - components that draw a selected/primary state read it so
        they always agree with each other.
    **/
    emphasis:EmphasisStyle
}
