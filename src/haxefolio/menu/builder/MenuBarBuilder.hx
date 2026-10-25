package haxefolio.menu.builder;

import haxefolio.menu.builder.components.NormalMenu;
import haxefolio.menu.builder.components.HomeButton;
import haxefolio.menu.builder.components.SiteNameLabel;
import haxefolio.menu.builder.components.HamburgerButton;
import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.Spacer;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.core.Component;
import haxefolio.ElementShadow;
import haxefolio.appearance.AppearanceContext;
import haxefolio.HaxeFolioApp;
import haxefolio.HaxeFolioConfig;
import haxefolio.MenuLayout;
import haxefolio.ResponsivityController;
import haxefolio.Viewport;
import haxefolio.menu.MenuBarItem;
import haxefolio.menu.SideBarController;
import js.Browser;
import js.html.Element;
import js.html.KeyboardEvent;

/** The menu's two homes: the bar on top, and the rail along the left edge for the `Rail` layout **/
typedef MenuBarBuildResult = {
    menuBar:MenuBar,
    menuRail:VBox
}

/*
    A persistent widget moves between its holder in the menu bar, which keeps its place in the bar's
    order, and its place in the rail: before the rail's spacer for a left item, after it for a right one.
*/
private typedef PersistentWidget = {
    component:Component,
    barHolder:Box,
    isLeft:Bool
}

class MenuBarBuilder
{
    private static inline final SOURCE_REFERENCE:String = "menubar";
    private static inline final RAIL_SOURCE_REFERENCE:String = "rail";
    private static inline final DEFAULT_HOME_ICON:String = "haxefolio/images/home_btn_icon.svg";

    // must match the dropdown's corner radius in the stylesheet (`.haxefolio-normal-menu`)
    private static inline final DROPDOWN_CORNER_RADIUS:Int = 8;

    // HaxeUI offsets a label's text by 1px on each side
    private static inline final SITE_NAME_TEXT_INSET:Float = 2;

    public static function build(config:HaxeFolioConfig):MenuBarBuildResult
    {
        var menuBar:MenuBar = new MenuBar();
        menuBar.percentWidth = 100;
        menuBar.addClass("haxefolio-menubar");
        if (config.menubar.showChevrons != false)
            menuBar.addClass("haxefolio-menubar-chevrons");

        var dropdownOpen:Bool = false;

        /*
            HaxeUI closes a dropdown on an outside click or a selection, but not on Esc. An Esc that
            closed one is marked handled, so that nothing else on the page reacts to it too.
        */
        Browser.document.addEventListener("keydown", (event:KeyboardEvent) -> {
            if (event.key != "Escape" || !dropdownOpen)
                return;

            event.preventDefault();
            menuBar.closeCurrentMenu();
        });

        menuBar.onMenuOpened = event -> {
            dropdownOpen = true;
            placeOpenDropdown(menuBar, event.menu);
        };
        menuBar.onMenuClosed = _ -> {
            dropdownOpen = false;
        };

        var hamburgerButton:Component = new HamburgerButton(SOURCE_REFERENCE, SideBarController.open);
        hamburgerButton.hidden = true;
        menuBar.addComponent(hamburgerButton);

        var homeIcon:String = config.homeIcon ?? DEFAULT_HOME_ICON;

        var siteNameLabel:SiteNameLabel = new SiteNameLabel(SOURCE_REFERENCE, config.siteName, HaxeFolioApp.navigateToDefault);
        menuBar.addComponent(siteNameLabel);

        var homeButton:HomeButton = new HomeButton(SOURCE_REFERENCE, homeIcon, HaxeFolioApp.navigateToDefault);
        homeButton.hidden = true;
        menuBar.addComponent(homeButton);

        var menuRail:VBox = new VBox();
        menuRail.percentHeight = 100;
        menuRail.addClass("haxefolio-menu-rail");
        menuRail.hidden = true;
        menuRail.addComponent(new HamburgerButton(RAIL_SOURCE_REFERENCE, SideBarController.open));
        menuRail.addComponent(new HomeButton(RAIL_SOURCE_REFERENCE, homeIcon, HaxeFolioApp.navigateToDefault));

        var railSpacer:Spacer = new Spacer();
        railSpacer.percentHeight = 100;
        menuRail.addComponent(railSpacer);

        var collapsibleComponents:Array<Component> = [];
        var persistentWidgets:Array<PersistentWidget> = [];

        for (item in config.menubar.left)
            addMenuBarItem(menuBar, collapsibleComponents, persistentWidgets, item, true);

        var spacer:Spacer = new Spacer();
        spacer.percentWidth = 100;
        menuBar.addComponent(spacer);

        for (item in config.menubar.right)
            addMenuBarItem(menuBar, collapsibleComponents, persistentWidgets, item, false);

        var widgetsInRail:Bool = false;

        /*
            The stylesheet can't see the layout: the bar's padding and gaps key on these state
            classes instead. The site name label carries its own, since HaxeUI doesn't restyle a
            component's children when the component's class changes. A dropdown open at the moment
            of a change is closed - its trigger may be about to disappear or move.
        */
        ResponsivityController.onMenuLayoutChange(layout -> {
            var collapsed:Bool = layout != Expanded;

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

            for (component in collapsibleComponents)
                component.hidden = collapsed;

            hamburgerButton.hidden = !collapsed;
            menuBar.hidden = layout == Rail;
            menuRail.hidden = layout != Rail;

            if (widgetsInRail != (layout == Rail))
            {
                widgetsInRail = layout == Rail;
                movePersistentWidgets(persistentWidgets, menuRail, railSpacer, widgetsInRail);
            }

            Browser.window.requestAnimationFrame(_ -> fitSiteName(menuBar, siteNameLabel, homeButton, spacer));
        });

        var barObserver:Dynamic = js.Syntax.code("new ResizeObserver({0})", _ -> Browser.window.requestAnimationFrame(_ -> fitSiteName(menuBar, siteNameLabel, homeButton, spacer)));
        barObserver.observe(menuBar.element);

        return {menuBar: menuBar, menuRail: menuRail};
    }

    /*
        A collapsed bar shows the home button in place of the site name once the name no longer fits
        beside the bar's other visible items. Run a frame after a change, once HaxeUI has sized them.
    */
    private static function fitSiteName(menuBar:MenuBar, siteNameLabel:SiteNameLabel, homeButton:HomeButton, spacer:Spacer):Void
    {
        var showName:Bool = ResponsivityController.menuLayout != Collapsed || siteNameWidth(siteNameLabel) <= widthLeftForSiteName(menuBar, [siteNameLabel, homeButton, spacer]);

        siteNameLabel.hidden = !showName;
        homeButton.hidden = showName;
    }

    // measured from the text, so known while the label is hidden too
    private static function siteNameWidth(siteNameLabel:SiteNameLabel):Float
    {
        var textElement:Element = siteNameLabel.element.firstElementChild ?? siteNameLabel.element;
        var paddings:Float = (siteNameLabel.style?.paddingLeft ?? 0.0) + (siteNameLabel.style?.paddingRight ?? 0.0);
        return MenuBuilderHelpers.measureSingleLine(textElement) + paddings + SITE_NAME_TEXT_INSET;
    }

    // the bar's width, less its padding, the gaps between its visible items, and the widths of those but `unmeasured`
    private static function widthLeftForSiteName(menuBar:MenuBar, unmeasured:Array<Component>):Float
    {
        var width:Float = menuBar.element.getBoundingClientRect().width / Toolkit.scaleX;
        width -= (menuBar.style?.paddingLeft ?? 0.0) + (menuBar.style?.paddingRight ?? 0.0);

        var visibleCount:Int = 0;
        for (child in menuBar.childComponents)
        {
            if (child.hidden)
                continue;

            visibleCount++;

            if (unmeasured.indexOf(child) == -1)
            {
                var childWidth:Null<Float> = child.width;
                width -= childWidth ?? 0.0;
            }
        }

        return width - Math.max(0, visibleCount - 1) * (menuBar.style?.horizontalSpacing ?? 0.0);
    }

    private static function movePersistentWidgets(persistentWidgets:Array<PersistentWidget>, menuRail:VBox, railSpacer:Spacer, toRail:Bool):Void
    {
        for (widget in persistentWidgets)
        {
            if (toRail)
            {
                widget.barHolder.removeComponent(widget.component, false);
                if (widget.isLeft)
                    menuRail.addComponentAt(widget.component, menuRail.getComponentIndex(railSpacer));
                else
                    menuRail.addComponent(widget.component);
            }
            else
            {
                menuRail.removeComponent(widget.component, false);
                widget.barHolder.addComponent(widget.component);
            }
        }
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

    private static function addMenuBarItem(menuBar:MenuBar, collapsibleComponents:Array<Component>, persistentWidgets:Array<PersistentWidget>, item:MenuBarItem, isLeft:Bool):Void
    {
        switch item
        {
            case NormalMenu(slug, items, defaultText):
                var menu:NormalMenu = new NormalMenu(slug, items, defaultText);
                ElementShadow.apply(menu.element, AppearanceContext.current.shadows.menuDropdown);
                menu.onWidthRefitted = () -> placeOpenDropdown(menuBar, menu);
                menuBar.addComponent(menu);
                collapsibleComponents.push(menu);
            case Widget(componentFactory, persistent):
                var component:Component = componentFactory();
                component.verticalAlign = "center";

                if (persistent != true)
                {
                    menuBar.addComponent(component);
                    collapsibleComponents.push(component);
                    return;
                }

                var barHolder:Box = new Box();
                barHolder.addClass("haxefolio-menubar-widget-holder");
                barHolder.verticalAlign = "center";
                barHolder.addComponent(component);
                menuBar.addComponent(barHolder);
                persistentWidgets.push({component: component, barHolder: barHolder, isLeft: isLeft});
        }
    }
}
