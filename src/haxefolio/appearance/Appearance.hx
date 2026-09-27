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
        Which treatment means "selected" for a component holding one of several peer values
        (`ChoiceButton`) - components with that role read it so they always agree with each other.
        See `EmphasisStyle` for why this is split from `actionEmphasis`.
    **/
    selectionEmphasis:EmphasisStyle,

    /**
        Which treatment means "primary" for a single call-to-action (`ActionButton`,
        `CommitTextField`'s commit button) - components with that role read it so they always agree
        with each other. See `EmphasisStyle` for why this is split from `selectionEmphasis`.
    **/
    actionEmphasis:EmphasisStyle
}
