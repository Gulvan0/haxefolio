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
        An ordinary dropdown menu identified by `slug` (also used to build its CSS id and, absent
        `defaultText`, its locale key - see `haxefolio.menubar.menu.<slug>`), containing `items`.
        `defaultText`, if given, is used verbatim as the menu's initial label - interpreted the
        same way any HaxeUI `.text` property is (a literal by default, or - enclosed in `{{}}` - a
        locale key); if omitted, the label defaults to the `haxefolio.menubar.menu.<slug>` locale
        key. Either way, `MenuFacade.updateMenuLabelText` can change it later.
    **/
    NormalMenu(slug:String, items:Array<MenuItemDefinition>, ?defaultText:String);

    /**
        A custom `component`, wrapped in its own `Menu`. Hidden when the menu bar collapses to its
        mobile layout unless `persistent` is `true`.
    **/
    Widget(component:Component, ?persistent:Bool);
}
