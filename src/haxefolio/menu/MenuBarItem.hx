package haxefolio.menu;

import haxe.ui.core.Component;

/**
    One entry in `MenuBarConfig.left`/`right`, in the order it should be laid out.
**/
enum MenuBarItem
{
    /**
        The site name label - navigates to the default page when clicked. Only its text is
        user-defined (`HaxeFolioConfig.siteName`); its other behavior is constant.
    **/
    SiteName;

    /**
        An ordinary dropdown menu identified by `slug` (used to build its locale keys, see
        `haxefolio.menubar.menu.<slug>`), containing `items`.
    **/
    NormalMenu(slug:String, items:Array<MenuItemDefinition>);

    /**
        A custom `component`, wrapped in its own `Menu`. Hidden when the menu bar collapses to its
        mobile layout unless `persistent` is `true`.
    **/
    Widget(component:Component, ?persistent:Bool);
}
