package haxefolio.appearance;

/*
    Governs how a component with a selected/primary visual state marks that state - `Filled` a
    solid `accent` fill, `Outlined` an `accentTint` fill with an `accentMuted` border.

    Not a colour but a semantic choice - which treatment means "selected"/"primary" - so it lives
    in code (as part of `Appearance`) rather than in a stylesheet: every component sharing a role
    must agree on it, and only code can say which one is in use. A stylesheet can restyle both
    treatments. There is no CSS channel for selecting it; components read it from
    `AppearanceContext` when they are built.

    Two independent roles read it, because a host's accent hue may collide with its content
    imagery for a persistent chip-like selection without that being a reason to soften its actual
    call-to-action buttons - see `Appearance.selectionEmphasis` (`ChoiceButton`) and
    `Appearance.actionEmphasis` (`ActionButton`'s primary state, `CommitTextField`'s commit
    button). A host free of that collision typically sets neither and keeps `Filled` throughout;
    one that has it sets `selectionEmphasis: Outlined` alone far more often than it sets
    `actionEmphasis: Outlined` too, since a screen's one primary action usually still wants full
    weight.
*/
enum EmphasisStyle
{
    Filled;
    Outlined;
}
