package haxefolio.structure;

/**
    What a `Tabs` region's tabs mean to each other. The rule for choosing: if the tabs can be saved
    together, it is `Navigate`; if choosing one discards the other, it is `Choose`.
**/
enum TabRole
{
    /**
        One form cut into groups: shared state and a shared footer. Drawn as flush underlined tabs.
        The frame title stays fixed. A page holding an invalid field marks its tab (see `ErrorMarker`).
    **/
    Navigate;

    /**
        Alternative forms, nothing shared. Drawn as a segmented control on a recessed track. The frame
        title follows the tab (see `TabPage.title`) and the host relabels its primary action per tab
        through the `onSelect` of `Region.Tabs`.
    **/
    Choose;
}
