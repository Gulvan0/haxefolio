package haxefolio.menu;

import haxe.ui.core.Component;

/**
    One entry in `MenuBarConfig.left`/`right`, in the order it should be laid out.
**/
enum MenuBarItem
{
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
        A custom component built by `componentFactory` and wrapped in its own `Menu`. The factory
        is only invoked once the menu bar itself is being built, i.e. after `Toolkit.init()` has
        run, since HaxeUI components can't be constructed before that. Hidden when the menu bar
        collapses to its mobile layout unless `persistent` is `true`.
    **/
    Widget(componentFactory:Void->Component, ?persistent:Bool);
}
