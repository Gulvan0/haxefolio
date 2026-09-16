package haxefolio.form.plumbing;

/*
    Governs how a component with a selected/primary visual state (ChoiceButton, ToggleButton)
    marks that state - `Filled` a solid `accent` fill, `Outlined` an `accentTint` fill with an
    `accentMuted` border. Not a per-component property: it comes from the enclosing host via the
    `haxefolio-emphasis-outlined` class (absent it, `Filled` is the default) on any ancestor, so
    every component inside a host agrees on what "active" looks like without each one needing to
    be told individually.
*/
enum EmphasisStyle
{
    Filled;
    Outlined;
}
