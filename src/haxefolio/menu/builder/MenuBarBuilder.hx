package haxefolio.menu.builder;

import haxefolio.menu.builder.components.NormalMenu;
import haxefolio.menu.builder.components.SiteNameLabel;
import haxefolio.menu.builder.components.HamburgerButton;
import haxe.ui.components.Button;
import haxe.ui.components.Spacer;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.core.Component;
import haxefolio.ElementShadow;
import haxefolio.HaxeFolioApp;
import haxefolio.HaxeFolioConfig;
import haxefolio.ResponsivityController;
import haxefolio.Viewport;
import haxefolio.menu.MenuBarItem;
import haxefolio.menu.SideBarController;
import js.Browser;
import js.html.KeyboardEvent;

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

    // must match the dropdown's corner radius in the stylesheet (`.haxefolio-normal-menu`)
    private static inline final DROPDOWN_CORNER_RADIUS:Int = 8;

    public static function build(config:HaxeFolioConfig):MenuBarBuildResult
    {
        var menuBar:MenuBar = new MenuBar();
        menuBar.percentWidth = 100;
        menuBar.addClass("haxefolio-menubar");


        // HaxeUI closes a dropdown on an outside click or a selection, but not on Esc
        Browser.document.addEventListener("keydown", (event:KeyboardEvent) -> {
            if (event.key == "Escape")
                menuBar.closeCurrentMenu();
        });

        menuBar.onMenuOpened = event -> placeOpenDropdown(menuBar, event.menu);

        var hamburgerButton:Component = new HamburgerButton(SOURCE_REFERENCE, SideBarController.open);
        hamburgerButton.hidden = true;
        menuBar.addComponent(hamburgerButton);

        var siteNameLabel:SiteNameLabel = new SiteNameLabel(SOURCE_REFERENCE, config.siteName, HaxeFolioApp.navigateToDefault);
        menuBar.addComponent(siteNameLabel);

        /*
            The stylesheet can't see the breakpoint: the padding and gaps key on these state
            classes instead. The site name label carries its own, since HaxeUI doesn't restyle a
            component's children when the component's class changes. A dropdown open at the moment
            of crossing is closed - its trigger may be about to disappear with the rest of the
            collapsible items.
        */
        ResponsivityController.onCollapseChange(collapsed -> {
            if (collapsed)
            {
                menuBar.swapClass("haxefolio-menubar-collapsed", "haxefolio-menubar-expanded");
                siteNameLabel.removeClass("haxefolio-site-name-label-expanded");
            }
            else
            {
                menuBar.swapClass("haxefolio-menubar-expanded", "haxefolio-menubar-collapsed");
                siteNameLabel.addClass("haxefolio-site-name-label-expanded");
            }

            menuBar.closeCurrentMenu();
        });

        var collapsibleComponents:Array<Component> = [];

        for (item in config.menubar.left)
            addMenuBarItem(menuBar, collapsibleComponents, item);

        var spacer:Spacer = new Spacer();
        spacer.percentWidth = 100;
        menuBar.addComponent(spacer);

        for (item in config.menubar.right)
            addMenuBarItem(menuBar, collapsibleComponents, item);

        return {menuBar: menuBar, hamburgerButton: hamburgerButton, collapsibleComponents: collapsibleComponents};
    }

    /*
        Runs on every open, once HaxeUI has positioned the dropdown, and again whenever the dropdown
        re-fits its width to its labels while open (see NormalMenu) - HaxeUI positions it only
        once, at open, so the same placement rule is applied here to keep it right after a re-fit:
        left-aligned under its trigger, or right-aligned to it when that would overflow the screen.

        The corner under the trigger is square, and the top edge beside the trigger is HaxeUI's
        filler, which is refitted here too: HaxeUI fits it around a rounded top-right corner only.
    */
    private static function placeOpenDropdown(menuBar:MenuBar, menu:Menu):Void
    {
        var trigger:Null<Button> = findOpenTrigger(menuBar);
        if (trigger == null)
            return;

        var flipped:Bool = trigger.screenLeft + menu.width > Viewport.width();
        menu.left = flipped ? trigger.screenLeft + trigger.width - menu.width : trigger.screenLeft;

        if (flipped)
            menu.addClass("haxefolio-normal-menu-flipped");
        else
            menu.removeClass("haxefolio-normal-menu-flipped");

        var filler:Null<Component> = menu.findComponent("menu-filler", false);
        if (filler == null)
            return;

        var cornerOffset:Float = DROPDOWN_CORNER_RADIUS - 1;
        var fillerWidth:Float = menu.width - trigger.width - cornerOffset + 1;

        filler.hidden = fillerWidth <= 0;
        filler.width = Math.max(fillerWidth, 0);
        filler.left = flipped ? cornerOffset : trigger.width - 1;
    }

    // the menu bar's own button for the open menu: the only one of them left selected while it is open
    private static function findOpenTrigger(menuBar:MenuBar):Null<Button>
    {
        for (child in menuBar.childComponents)
            if (child.hasClass("menubar-button") && Std.isOfType(child, Button) && cast(child, Button).selected)
                return cast(child, Button);

        return null;
    }

    private static function addMenuBarItem(menuBar:MenuBar, collapsibleComponents:Array<Component>, item:MenuBarItem):Void
    {
        var component:Component = buildMenuBarItem(menuBar, item);
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

    private static function buildMenuBarItem(menuBar:MenuBar, item:MenuBarItem):Component
    {
        switch item
        {
            case NormalMenu(slug, items, defaultText):
                var menu:NormalMenu = new NormalMenu(slug, items, defaultText);
                ElementShadow.apply(menu.element, "0 8px 28px rgba(24, 26, 31, 0.16)");
                menu.onWidthRefitted = () -> placeOpenDropdown(menuBar, menu);
                return menu;
            case Widget(componentFactory, _):
                var component:Component = componentFactory();
                component.verticalAlign = "center";
                return component;
        }
    }
}
