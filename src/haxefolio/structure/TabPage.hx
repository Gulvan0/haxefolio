package haxefolio.structure;

import haxe.ui.core.Component;

/**
    One page of a `Tabs` region.
**/
typedef TabPage = {
    /**
        The tab's caption, interpreted like any HaxeUI `.text` property (see `LocaleUtils`). There is
        no ellipsis: a caption that does not fit its tab is cut off, so keep it short (and re-check it
        in every shipped locale).
    **/
    label:String,

    /**
        A resource shown before the label.
    **/
    ?icon:String,

    /**
        The page. It sits in its own `ScrollArea` filling the region, so pages may differ in height
        and each keeps its own scroll offset.
    **/
    content:Component,

    /**
        `Choose` only (giving one to a `Navigate` page throws): the `Header` region's title while this
        tab is active; a page without one shows the `Header`'s own. A `Choose` region with titled
        pages needs a `Header` to show them.
    **/
    ?title:String,

    /**
        The host's flag for an invalid field on this page; the tab shows a marker while it is `active`.
        The space for the marker is reserved for the tab's whole life, so it appearing moves nothing.
    **/
    ?errorMarker:ErrorMarker
}
