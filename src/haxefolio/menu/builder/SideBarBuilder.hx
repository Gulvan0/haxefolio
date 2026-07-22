package haxefolio.menu.builder;

import haxefolio.menu.builder.components.SidebarGroupItem;
import haxefolio.menu.builder.components.SidebarGroupHeader;
import haxefolio.menu.builder.components.SiteNameLabel;
import haxefolio.menu.builder.components.HamburgerButton;
import haxe.ui.components.Spacer;
import haxe.ui.containers.HBox;
import haxe.ui.containers.SideBar;
import haxe.ui.containers.VBox;
import haxe.ui.layouts.VerticalLayout;
import haxefolio.HaxeFolioApp;
import haxefolio.HaxeFolioConfig;
import haxefolio.menu.MenuAction;

class SideBarBuilder
{
    private static inline final SOURCE_REFERENCE:String = "sidebar";

    public static function build(config:HaxeFolioConfig):SideBar
    {
        var sideBar:SideBar = new SideBar();
        sideBar.position = "left";
        sideBar.method = "float";
        sideBar.percentHeight = 100;
        sideBar.layout = new VerticalLayout();
        sideBar.addClass("haxefolio-sidebar");

        var firstRow:HBox = new HBox();
        firstRow.addComponent(new HamburgerButton(SOURCE_REFERENCE, sideBar.hide));
        firstRow.addComponent(new SiteNameLabel(SOURCE_REFERENCE, config.siteName, () -> {
            sideBar.hide();
            HaxeFolioApp.navigateToDefault();
        }));
        sideBar.addComponent(firstRow);

        var entriesTopSpacer:Spacer = new Spacer();
        entriesTopSpacer.addClass("haxefolio-sidebar-entries-top-spacer");
        sideBar.addComponent(entriesTopSpacer);

        for (item in config.menubar.left.concat(config.menubar.right))
            switch item
            {
                case NormalMenu(slug, items):
                    sideBar.addComponent(buildGroup(sideBar, slug, 'haxefolio.menubar.menu', items));
                case SiteName, Widget(_, _):
            }

        if (config.sidebarExtras != null)
            for (group in config.sidebarExtras)
                sideBar.addComponent(buildGroup(sideBar, group.slug, 'haxefolio.sidebar.extra_group', group.items));

        return sideBar;
    }

    private static function buildGroup(sideBar:SideBar, slug:String, keyPrefix:String, items:Array<{slug: String, action: MenuAction}>):VBox
    {
        var baseKey:String = keyPrefix + "." + slug;
        var group:VBox = new VBox();

        group.addComponent(new SidebarGroupHeader(slug, Utils.localeBinding(baseKey)));

        for (item in items)
        {
            var text:String = Utils.localeBinding('$baseKey.item.${item.slug}');
            group.addComponent(new SidebarGroupItem(slug, item.slug, text, () -> {
                sideBar.hide();
                MenuBuilderHelpers.invokeAction(item.action);
            }));
        }

        return group;
    }
}
