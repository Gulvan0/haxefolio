package haxefolio.structure;

import haxe.ui.core.Component;

/**
    One region of a `RegionStack`. Every region but the scrolling one has a constant, declared
    height; the scrolling one takes whatever the frame has left.

    Only the regions that can be built from what exists today are listed. `Search` joins as its
    component is built - a constructor here plus a token it reads its height from (see
    `GeometryTokens`), and nothing in `RegionStack`'s arithmetic changes.
**/
enum Region
{
    /**
        The title row (see `HeaderBar`): `title`, interpreted like any HaxeUI `.text` property, and a
        close control that dismisses the overlay. `height` overrides the `headerHeight` token for
        this instance only. `hideClose` drops the close control, for a host whose footer carries the
        exit; a stack with nothing to dismiss (an embedded panel) has no close control either way.
    **/
    Header(title:String, ?height:ByWidth<Int>, ?hideClose:Bool);

    /**
        A row of buttons (see `ActionBar`), typically the overlay's footer. `height` overrides the
        `actionBarHeight` token for this instance only.
    **/
    Actions(bar:ActionBar, ?height:ByWidth<Int>);

    /**
        A fixed-height region holding arbitrary content. `height` is declared, never measured:
        content that does not fit is cut off, not accommodated. `Custom` is the one region that
        insists on a number, because the framework has no constant for a region it did not design.
    **/
    Custom(height:ByWidth<Int>, content:Component);

    /**
        The scrolling area: vertical scrolling only, at the height the arithmetic leaves it (see
        `ScrollArea`). A stack has at most one scrolling area: a `Scroll` region or a `Tabs` one, never both.
    **/
    Scroll(content:Component);

    /**
        A tab strip (see `TabStrip`) with, below it, the scrolling area holding the pages: the strip is a
        fixed region (`stripHeight` overrides the `tabStripHeight` token for this instance only) and the
        pages fill the height the arithmetic leaves, each in its own `ScrollArea` inside a slot that
        never changes size when the tab is switched. Pages may differ in height and each keeps its own
        scroll offset.

        `role` says what the tabs mean to each other (see `TabRole`). `onSelect` runs with the page
        index each time the user picks a tab other than the current one - for a `Choose` region, the
        hook for relabelling the host's primary action; it is not called for the initial tab (the first)
        nor for changes made by the host. A stack has at most one `Tabs` region, and it counts as the
        stack's scrolling area (see `Scroll`).
    **/
    Tabs(role:TabRole, pages:Array<TabPage>, ?stripHeight:ByWidth<Int>, ?onSelect:Int->Void);
}
