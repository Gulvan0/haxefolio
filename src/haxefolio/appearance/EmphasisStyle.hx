package haxefolio.appearance;

/*
    Governs how a component with a selected/primary visual state (ChoiceButton, ToggleButton, the
    commit button of CommitTextField) marks that state - `Filled` a solid `accent` fill, `Outlined`
    an `accentTint` fill with an `accentMuted` border.

    Not a colour but a semantic choice - which treatment means "primary" - so it lives in code (as
    part of `Appearance`) rather than in a stylesheet: every component must agree on it, and only
    code can say which one is in use. A stylesheet can restyle both treatments. There is no CSS
    channel for selecting it; components read it from `AppearanceContext` when they are built.
*/
enum EmphasisStyle
{
    Filled;
    Outlined;
}
