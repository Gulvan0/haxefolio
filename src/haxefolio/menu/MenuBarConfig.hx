package haxefolio.menu;

/**
    The menu bar's items, grouped by which side of the bar they're bound to. Order within each
    array is layout order.
**/
typedef MenuBarConfig = {
    left:Array<MenuBarItem>,
    right:Array<MenuBarItem>,

    /**
        Whether each `NormalMenu` label shows a chevron (pointing down, or up while its dropdown is
        open) after its text. Defaults to `true`.
    **/
    ?showChevrons:Bool
}
