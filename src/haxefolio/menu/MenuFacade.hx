package haxefolio.menu;

import haxe.ui.components.Button;
import haxe.ui.containers.SideBar;
import haxe.ui.containers.menus.MenuBar;
import haxefolio.menu.builder.components.NormalMenu;
import haxefolio.menu.builder.components.NormalMenuItem;
import haxefolio.menu.builder.components.SidebarGroupHeader;
import haxefolio.menu.builder.components.SidebarGroupItem;
import haxefolio.menu.builder.components.SiteNameLabel;

/*
    Relies on the changes in https://github.com/haxeui/haxeui-core/pull/703
    being present in the current version of the haxeui-core library (if this
    PR hasn't been merged yet, replicate these changes in your local
    haxeui-core fork)
*/

/**
    The single exposed access point for the menu bar/side bar pair: public, read-only-from-outside
    references to both (e.g. for one-time style adjustment right after `HaxeFolioApp.init`
    returns), plus the runtime intents that must touch both together, so a framework user can
    never update one without the other going stale. Wired up internally by `HaxeFolioApp.init`;
    nothing here is usable before that has run.
**/
class MenuFacade
{
    public static var menuBar(default, null):MenuBar;
    public static var sideBar(default, null):SideBar;

    @:allow(haxefolio.HaxeFolioApp)
    private static function init(menuBar:MenuBar, sideBar:SideBar):Void
    {
        MenuFacade.menuBar = menuBar;
        MenuFacade.sideBar = sideBar;
    }

    /**
        Updates the site name label's text in both the menu bar and the side bar together. `text`
        is interpreted the same way any HaxeUI `.text` property is: a literal by default, or -
        enclosed in `{{}}` - a locale key, re-resolved on every locale change.
    **/
    public static function updateSiteNameLabelText(text:String):Void
    {
        var sidebarLabel:SiteNameLabel = sideBar.findComponent("haxefolio-site-name-label-sidebar", SiteNameLabel);
        sidebarLabel.text = text;

        var menuBarLabel:SiteNameLabel = menuBar.findComponent("haxefolio-site-name-label-menubar", SiteNameLabel);
        menuBarLabel.text = text;
    }

    /**
        Updates the label text of the `NormalMenu` identified by `slug`, and its mirrored side bar
        group header, together. `text` is interpreted the same way `updateSiteNameLabelText`'s is.
        Throws if no such `NormalMenu` is present in the menu bar.
    **/
    public static function updateMenuLabelText(slug:String, text:String):Void
    {
        var menu:NormalMenu = menuBar.findComponent('haxefolio-normal-menu-$slug', NormalMenu);

        if (menu == null)
            throw 'MenuFacade: no NormalMenu with slug "$slug" found in the menu bar.';

        menu.text = text;

        /*
            haxe.ui.containers.menus.MenuBar never actually shows `menu` in the bar row - it builds
            an internal proxy Button per NormalMenu and clones whatever locale registration `menu`
            had at that exact construction moment onto it (LocaleManager.cloneForComponent), then
            never re-clones it again. So the proxy keeps a permanently stale registration pointing
            at whatever locale key `menu` had at construction, independent of anything we do to
            `menu` itself afterwards - on a later locale change it would silently overwrite our
            update. There's no public API to reach it (MenuBar's own composite builder is a
            file-private type, and it refuses removeComponent so re-adding isn't an option either),
            so this reaches around it via Reflect on the private _menus/_buttons pairing MenuBar's
            builder keeps internally. Depends on that internal shape - a haxeui-core upgrade that
            restructures MenuBar could silently break this half of the fix.
        */
        var proxyButton:Null<Button> = findMenuBarProxyButton(menu);
        if (proxyButton != null)
            proxyButton.text = text;

        var header:SidebarGroupHeader = sideBar.findComponent('haxefolio-sidebar-group-header-$slug', SidebarGroupHeader);
        header.text = text;
    }

    @:access(haxe.ui.core.Component)
    private static function findMenuBarProxyButton(menu:NormalMenu):Null<Button>
    {
        var builder:Dynamic = menuBar._compositeBuilder;
        var menus:Null<Array<Dynamic>> = Reflect.field(builder, "_menus");
        var buttons:Null<Array<Dynamic>> = Reflect.field(builder, "_buttons");

        if (menus == null || buttons == null)
            return null;

        var index:Int = menus.indexOf(menu);
        return index >= 0 ? buttons[index] : null;
    }

    /**
        Updates the label text of the item identified by `itemSlug` within the `NormalMenu`
        identified by `menuSlug`, and its mirrored side bar item, together. `text` is interpreted
        the same way `updateSiteNameLabelText`'s is. Throws if no such item is present in the menu
        bar.
    **/
    public static function updateMenuItemLabelText(menuSlug:String, itemSlug:String, text:String):Void
    {
        var item:NormalMenuItem = menuBar.findComponent('haxefolio-normal-menu-$menuSlug-item-$itemSlug', NormalMenuItem);

        if (item == null)
            throw 'MenuFacade: no item "$itemSlug" found in NormalMenu "$menuSlug" in the menu bar.';

        item.text = text;

        var mirrored:SidebarGroupItem = sideBar.findComponent('haxefolio-sidebar-group-item-$menuSlug-$itemSlug', SidebarGroupItem);
        mirrored.text = text;
    }

    /**
        Shows the item identified by `itemSlug` within the `NormalMenu` identified by `menuSlug`,
        and its mirrored side bar item, together. Throws if no such item is present in the menu bar.
    **/
    public static function showMenuItem(menuSlug:String, itemSlug:String):Void
    {
        setMenuItemHidden(menuSlug, itemSlug, false);
    }

    /**
        Hides the item identified by `itemSlug` within the `NormalMenu` identified by `menuSlug`,
        and its mirrored side bar item, together. Throws if no such item is present in the menu bar.
    **/
    public static function hideMenuItem(menuSlug:String, itemSlug:String):Void
    {
        setMenuItemHidden(menuSlug, itemSlug, true);
    }

    private static function setMenuItemHidden(menuSlug:String, itemSlug:String, hidden:Bool):Void
    {
        var item:NormalMenuItem = menuBar.findComponent('haxefolio-normal-menu-$menuSlug-item-$itemSlug', NormalMenuItem);

        if (item == null)
            throw 'MenuFacade: no item "$itemSlug" found in NormalMenu "$menuSlug" in the menu bar.';

        item.hidden = hidden;

        var mirrored:SidebarGroupItem = sideBar.findComponent('haxefolio-sidebar-group-item-$menuSlug-$itemSlug', SidebarGroupItem);
        mirrored.hidden = hidden;
    }

    /**
        Shows the item identified by `itemSlug` within the `sidebarExtras` group identified by
        `groupSlug`. Throws if no such item is present in the side bar.
    **/
    public static function showSidebarExtraGroupItem(groupSlug:String, itemSlug:String):Void
    {
        setSidebarExtraGroupItemHidden(groupSlug, itemSlug, false);
    }

    /**
        Hides the item identified by `itemSlug` within the `sidebarExtras` group identified by
        `groupSlug`. Throws if no such item is present in the side bar.
    **/
    public static function hideSidebarExtraGroupItem(groupSlug:String, itemSlug:String):Void
    {
        setSidebarExtraGroupItemHidden(groupSlug, itemSlug, true);
    }

    private static function setSidebarExtraGroupItemHidden(groupSlug:String, itemSlug:String, hidden:Bool):Void
    {
        var item:SidebarGroupItem = sideBar.findComponent('haxefolio-sidebar-group-item-$groupSlug-$itemSlug', SidebarGroupItem);

        if (item == null)
            throw 'MenuFacade: no item "$itemSlug" found in sidebar extra group "$groupSlug".';

        item.hidden = hidden;
    }
}
