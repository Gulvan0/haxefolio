package haxefolio.structure;

import haxe.ui.core.Component;

/**
    One region of a `RegionStack`. Every region but the scrolling one has a constant, declared
    height; the scrolling one takes whatever the frame has left.

    Only the regions that can be built from what exists today are listed. `Header`, `Actions`,
    `Search` and `Tabs` join as their components are built - each one is a constructor here plus
    a token it reads its height from (see `GeometryTokens`), and nothing in `RegionStack`'s
    arithmetic changes.
**/
enum Region
{
    /**
        A fixed-height region holding arbitrary content. `height` is declared, never measured:
        content that does not fit is cut off, not accommodated. `Custom` is the one region that
        insists on a number, because the framework has no constant for a region it did not design.
    **/
    Custom(height:ByWidth<Int>, content:Component);

    /**
        The scrolling area: vertical scrolling only, at the height the arithmetic leaves it (see
        `ScrollArea`). A stack has at most one.
    **/
    Scroll(content:Component);
}
