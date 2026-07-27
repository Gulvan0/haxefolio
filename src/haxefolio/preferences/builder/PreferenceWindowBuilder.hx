package haxefolio.preferences.builder;

import haxe.ui.containers.HBox;
import haxe.ui.containers.TabView;
import haxefolio.overlay.OverlayContent;
import haxefolio.preferences.PreferenceRegistry;
import haxefolio.preferences.builder.components.PreferenceAutosaveNoticeLabel;
import haxefolio.preferences.builder.components.PreferenceResetButton;
import haxefolio.preferences.builder.components.PreferenceTabPage;

/*
    Builds the preference panel's content - tabs plus a reset button - independently of how it ends
    up presented. Called directly by HaxeFolioApp.showPreferences() (via a factory closure passed
    to HaxeFolioApp.showOverlay), which is also what tags the returned content with its slug-based
    id/class - see ModalOverlay/SideBarOverlay.
*/
class PreferenceWindowBuilder
{
    public static function build(tabIcons:Map<String, String>):OverlayContent
    {
        var content:OverlayContent = new OverlayContent();
        content.percentWidth = 100;
        content.percentHeight = 100;

        var tabView:TabView = new TabView();
        tabView.id = "haxefolio-preference-tabview";
        tabView.percentWidth = 100;
        tabView.percentHeight = 100;

        for (group in PreferenceRegistry.getGroups())
        {
            var tabPage:PreferenceTabPage = new PreferenceTabPage(group, tabIcons.get(group.tabId));

            for (detachable in tabPage.detachables)
                content.addDetachable(detachable);

            tabView.addComponent(tabPage);
        }

        content.addComponent(tabView);

        var footer:HBox = new HBox();
        footer.id = "haxefolio-preference-footer";
        footer.addClass("haxefolio-preference-footer");
        footer.percentWidth = 100;
        footer.addComponent(new PreferenceResetButton());
        footer.addComponent(new PreferenceAutosaveNoticeLabel());
        content.addComponent(footer);

        return content;
    }
}
