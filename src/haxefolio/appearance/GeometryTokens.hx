package haxefolio.appearance;

import haxefolio.ByMenuLayout;

/**
    Every constant the framework's height arithmetic uses, in one named table. Each of them is an
    input to sums like `scrollHeight = frameHeight - sum of fixed heights` that are needed before
    layout, which is why they live here rather than in a stylesheet: reading them back out of the
    style engine would make the arithmetic depend on cascade timing.

    Every sum in the framework reads from this table, so overriding a token propagates on its own.
    `ByMenuLayout` tokens may differ between the expanded and collapsed states (e.g. a taller header
    when collapsed, for a larger touch target).
**/
typedef GeometryTokens = {
    headerHeight:ByMenuLayout<Int>,
    actionBarHeight:ByMenuLayout<Int>,
    tabStripHeight:ByMenuLayout<Int>,
    searchBarHeight:ByMenuLayout<Int>,
    fieldHeight:ByMenuLayout<Int>,

    /**
        Height of the always-reserved message line under a field (see `HintLine`).
    **/
    messageLine:Int,

    /**
        Vertical gap between stacked rows.
    **/
    rowGap:Int,
    padding:Int,

    /**
        The dialog presentation's preferred frame size (see `HaxeFolioApp.present`). A short or
        narrow viewport still shrinks the frame; only the preferred size is set here.
    **/
    dialogWidth:Int,
    dialogHeight:Int
}
