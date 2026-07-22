package haxefolio.menu;

/**
    A side-bar-only group of entries, listed under `HaxeFolioConfig.sidebarExtras` - its main use
    is to replicate navigational aspects of the non-persistent menu bar widgets.
**/
typedef SidebarGroup = {
    /**
        Identifies this group - used to build its locale keys, e.g.
        `haxefolio.sidebar.extra_group.<slug>`.
    **/
    slug:String,

    /**
        The group's entries, each rendered as a clickable label under the group's header.
    **/
    items:Array<MenuItemDefinition>
}
