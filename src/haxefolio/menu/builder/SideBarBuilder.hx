package haxefolio.menu.builder;

import haxefolio.menu.SideBarController;
import haxefolio.menu.builder.components.SidebarGroupItem;
import haxefolio.menu.builder.components.SidebarGroupHeader;
import haxefolio.menu.builder.components.SiteNameLabel;
import haxefolio.menu.builder.components.HamburgerButton;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.HaxeFolioApp;
import haxefolio.HaxeFolioConfig;
import haxefolio.structure.EdgePanel;
import haxefolio.structure.ScrollArea;

/*
    The side bar: a header repeating the collapsed menu bar's row - same height, padding and gap,
    so the hamburger button and the site name sit exactly where the menu bar's own do - and below
    it a scrolling body holding one group per menu (in menu bar order), then the `sidebarExtras`
    groups.
*/
class SideBarBuilder
{
    private static inline final SOURCE_REFERENCE:String = "sidebar";

    public static function build(config:HaxeFolioConfig):EdgePanel
    {
        var sideBar:EdgePanel = new EdgePanel(Left, SideBarController.handleGone, SideBarController.close.bind(true));
        sideBar.addClass("haxefolio-sidebar");
        sideBar.scrim.addClass("haxefolio-sidebar-scrim");

        var header:HBox = new HBox();
        header.percentWidth = 100;
        header.addClass("haxefolio-sidebar-header");
        header.addComponent(new HamburgerButton(SOURCE_REFERENCE, SideBarController.close.bind(true), true));
        header.addComponent(new SiteNameLabel(SOURCE_REFERENCE, config.siteName, () -> {
            SideBarController.close();
            HaxeFolioApp.navigateToDefault();
        }));
        sideBar.addComponent(header);

        var body:VBox = new VBox();
        body.percentWidth = 100;
        body.addClass("haxefolio-sidebar-body");

        for (item in config.menubar.left.concat(config.menubar.right))
            switch item
            {
                case NormalMenu(slug, items, defaultText):
                    body.addComponent(buildGroup(slug, 'haxefolio.menubar.menu', items, body.childComponents.length > 0, defaultText));
                case Widget(_, _):
            }

        if (config.sidebarExtras != null)
            for (group in config.sidebarExtras)
                body.addComponent(buildGroup(group.slug, 'haxefolio.sidebar.extra_group', group.items, body.childComponents.length > 0));

        // takes the height the header leaves
        var scrollArea:ScrollArea = new ScrollArea(body);
        scrollArea.percentHeight = 100;
        sideBar.addComponent(scrollArea);

        return sideBar;
    }

    private static function buildGroup(slug:String, keyPrefix:String, items:Array<MenuItemDefinition>, hasGroupAbove:Bool, ?groupDefaultText:String):VBox
    {
        var baseKey:String = keyPrefix + "." + slug;
        var group:VBox = new VBox();
        group.percentWidth = 100;
        group.addClass("haxefolio-sidebar-group");

        if (hasGroupAbove)
            group.addClass("haxefolio-sidebar-group-divided");

        group.addComponent(new SidebarGroupHeader(slug, MenuBuilderHelpers.resolveLabelText(groupDefaultText, baseKey)));

        for (item in items)
        {
            var text:String = MenuBuilderHelpers.resolveLabelText(item.defaultText, '$baseKey.item.${item.slug}');
            group.addComponent(new SidebarGroupItem(slug, item.slug, text, () -> {
                SideBarController.close();
                MenuBuilderHelpers.invokeAction(item.action);
            }, item.icon, item.hiddenByDefault == true));
        }

        return group;
    }
}
