package haxefolio.menu;

/**
    The menu bar's items, grouped by which side of the bar they're bound to. Order within each
    array is layout order.
**/
typedef MenuBarConfig = {
    left:Array<MenuBarItem>,
    right:Array<MenuBarItem>
}
