package haxefolio.menu.builder;

import haxefolio.menu.builder.components.NormalMenu;
import haxefolio.menu.builder.components.SiteNameLabel;
import haxefolio.menu.builder.components.HamburgerButton;
import haxe.ui.components.Spacer;
import haxe.ui.containers.SideBar;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.core.Component;
import haxefolio.HaxeFolioApp;
import haxefolio.HaxeFolioConfig;
import haxefolio.menu.MenuBarItem;

/*
    The menu bar itself, plus the pieces `ResponsivityController` needs to react to
    `menuCollapseWidth` crossings: the hamburger button to reveal, and the subset of the menu bar's
    children (normal menus and non-persistent widgets) to hide when collapsed.
*/
typedef MenuBarBuildResult = {
    menuBar:MenuBar,
    hamburgerButton:Component,
    collapsibleComponents:Array<Component>
}

class MenuBarBuilder
{
    private static inline final SOURCE_REFERENCE:String = "menubar";

    public static function build(config:HaxeFolioConfig, sideBar:SideBar):MenuBarBuildResult
    {
        var menuBar:MenuBar = new MenuBar();
        menuBar.percentWidth = 100;
        menuBar.addClass("haxefolio-menubar");

        var hamburgerButton:Component = new HamburgerButton(SOURCE_REFERENCE, sideBar.show);
        hamburgerButton.hidden = true;
        menuBar.addComponent(hamburgerButton);

        menuBar.addComponent(new SiteNameLabel(SOURCE_REFERENCE, config.siteName, HaxeFolioApp.navigateToDefault));

        var collapsibleComponents:Array<Component> = [];

        for (item in config.menubar.left)
            addMenuBarItem(menuBar, collapsibleComponents, config, item);

        var spacer:Spacer = new Spacer();
        spacer.percentWidth = 100;
        menuBar.addComponent(spacer);

        for (item in config.menubar.right)
            addMenuBarItem(menuBar, collapsibleComponents, config, item);

        return {menuBar: menuBar, hamburgerButton: hamburgerButton, collapsibleComponents: collapsibleComponents};
    }

    private static function addMenuBarItem(menuBar:MenuBar, collapsibleComponents:Array<Component>, config:HaxeFolioConfig, item:MenuBarItem):Void
    {
        var component:Component = buildMenuBarItem(config, item);
        menuBar.addComponent(component);

        if (isCollapsible(item))
            collapsibleComponents.push(component);
    }

    private static function isCollapsible(item:MenuBarItem):Bool
    {
        return switch item
        {
            case NormalMenu(_, _, _): true;
            case Widget(_, persistent): persistent != true;
        }
    }

    private static function buildMenuBarItem(config:HaxeFolioConfig, item:MenuBarItem):Component
    {
        switch item
        {
            case NormalMenu(slug, items, defaultText):
                return new NormalMenu(slug, items, defaultText);
            case Widget(component, _):
                component.verticalAlign = "center";
                return component;
        }
    }
}
