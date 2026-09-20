package;

import haxe.ui.components.Label;
import haxe.ui.core.Component;
import haxefolio.HaxeFolioApp;
import haxefolio.HaxeFolioConfig;
import haxefolio.HaxeFolioConfigBuilder;
import haxefolio.menu.MenuAction;
import haxefolio.menu.MenuBarItem;
import haxefolio.menu.MenuFacade;
import js.Browser;
import overlay.CustomOverlayContent;
import pages.AboutPage;
import pages.FormDemoPage;
import pages.HomePage;
import pages.StructureDemoPage;
import pages.TextDemoPage;

class Main
{
    public static function main():Void
    {
        var config:HaxeFolioConfig = HaxeFolioConfigBuilder.init("haxefolio-sample", SamplePreferences)
            .setAppIcon("haxefolio/images/close_btn_icon.svg")
            .setSiteName("HaxeFolio Sample")
            .setDefaultTitleText("{{haxefolio.sample.default_title}}")
            .addLocale("en", "English")
            .addLocale("ru", "Русский")
            .addPage("home", params -> new HomePage(), true)
            .addPage("about", params -> new AboutPage())
            .addPage("text-demo", params -> new TextDemoPage())
            .addPage("form-demo", params -> new FormDemoPage())
            .addPage("structure-demo", params -> new StructureDemoPage())
            .addLeftMenubarItem(NormalMenu("navigation", []))
            .addNormalMenuItem("navigation", "home", NavigateTo(() -> "home"))
            .addNormalMenuItem("navigation", "about", NavigateTo(() -> "about"))
            .addLeftMenubarItem(NormalMenu("text-demo", [], "{{haxefolio.sample.menu_label_with_param, 2}}"))
            .addNormalMenuItem("text-demo", "open", NavigateTo(() -> "text-demo"), null, "Open")
            .addNormalMenuItem("text-demo", "reset-labels", Execute(resetLabels), null, "{{haxefolio.sample.reset_labels_label}}")
            .addLeftMenubarItem(NormalMenu("form-demo", []))
            .addNormalMenuItem("form-demo", "open", NavigateTo(() -> "form-demo"))
            .addLeftMenubarItem(NormalMenu("structure-demo", []))
            .addNormalMenuItem("structure-demo", "open", NavigateTo(() -> "structure-demo"))
            .addLeftMenubarItem(NormalMenu("overlay-demo", []))
            .addNormalMenuItem("overlay-demo", "plain", Execute(showPlainOverlay))
            .addNormalMenuItem("overlay-demo", "dismissible", Execute(showDismissibleOverlay))
            .addNormalMenuItem("overlay-demo", "mobile-variant", Execute(showMobileVariantOverlay))
            .addNormalMenuItem("overlay-demo", "long", Execute(showLongOverlay))
            .addNormalMenuItem("overlay-demo", "appearance", Execute(showAppearanceOverlay))
            .addRightMenubarItem(Widget(buildSettingsWidget, true))
            .setLanguagePreference(SamplePreferences.language)
            .buildConfig();

        HaxeFolioApp.init(config);
    }

    private static function buildSettingsWidget():Component
    {
        var settingsWidget:Label = new Label();
        settingsWidget.text = "⚙";
        settingsWidget.onClick = _ -> HaxeFolioApp.showPreferences();
        return settingsWidget;
    }

    /*
        Restores the site name and the "Navigation" menu/"Home" item labels to what TextDemoPage's
        buttons started them at, by pointing each back at its original locale key.
    */
    private static function resetLabels():Void
    {
        MenuFacade.updateSiteNameLabelText("HaxeFolio Sample");
        MenuFacade.updateMenuLabelText("navigation", "{{haxefolio.menubar.menu.navigation}}");
        MenuFacade.updateMenuItemLabelText("navigation", "home", "{{haxefolio.menubar.menu.navigation.item.home}}");
    }

    /*
        The simplest overlay: one Scroll region, everything else left to the presentation.
    */
    private static function showPlainOverlay():Void
        HaxeFolioApp.present("custom-plain", _ -> CustomOverlayContent.buildPlain());

    /*
        Its own footer button closes it via the dismiss handle its factory received.
    */
    private static function showDismissibleOverlay():Void
        HaxeFolioApp.present("custom-dismissible", CustomOverlayContent.buildDismissible);

    /*
        mobileContentFactory renders a genuinely different component tree while the breakpoint is
        collapsed than contentFactory does while expanded - the choice is made once, when the
        overlay is presented.
    */
    private static function showMobileVariantOverlay():Void
        HaxeFolioApp.present("custom-mobile-variant", _ -> CustomOverlayContent.buildDesktopVariant(), _ -> CustomOverlayContent.buildMobileVariant());

    /*
        Tall content plus a footer; also passes the host-side onDismissed callback, which must run
        after the content's own.
    */
    private static function showLongOverlay():Void
        HaxeFolioApp.present("custom-long", CustomOverlayContent.buildLong, null, null, () -> Browser.console.log("[overlay-demo] present.onDismissed"));

    /*
        Per-overlay appearance: Outlined emphasis and a style class.
    */
    private static function showAppearanceOverlay():Void
        HaxeFolioApp.present("custom-appearance", _ -> CustomOverlayContent.buildAppearance(), null, {emphasis: Outlined, styleClass: "sample-overlay-variant"});
}
