package haxefolio.preferences.builder;

import haxe.ui.containers.HBox;
import haxe.ui.containers.TabView;
import haxefolio.preferences.PreferenceRegistry;
import haxefolio.preferences.builder.components.PreferenceAutosaveNoticeLabel;
import haxefolio.preferences.builder.components.PreferenceResetButton;
import haxefolio.preferences.builder.components.PreferenceTabPage;

/*
    Builds the preference panel's content - tabs plus a reset button - independently of how it ends
    up presented. PreferenceSideBarOverlay and PreferenceModalOverlay each call build() to get their
    own fresh copy and are responsible for wrapping it in their own container/chrome.
*/
class PreferenceWindowBuilder
{
    public static function build(tabIcons:Map<String, String>):PreferenceWindowContent
    {
        var content:PreferenceWindowContent = new PreferenceWindowContent();
        content.id = "haxefolio-preference-content";
        content.addClass("haxefolio-preference-content");
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
