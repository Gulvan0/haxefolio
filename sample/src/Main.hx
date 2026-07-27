package;

import haxe.ui.components.Label;
import haxefolio.HaxeFolioApp;
import haxefolio.HaxeFolioConfig;
import haxefolio.HaxeFolioConfigBuilder;
import haxefolio.menu.MenuAction;
import haxefolio.menu.MenuBarItem;
import haxefolio.menu.MenuFacade;
import overlay.CustomOverlayContent;
import pages.AboutPage;
import pages.HomePage;
import pages.TextDemoPage;

class Main
{
    public static function main():Void
    {
        var settingsWidget:Label = new Label();
        settingsWidget.text = "⚙";
        settingsWidget.onClick = _ -> HaxeFolioApp.showPreferences();

        var config:HaxeFolioConfig = HaxeFolioConfigBuilder.init("haxefolio-sample", SamplePreferences)
            .setAppIcon("haxefolio/images/close_btn_icon.svg")
            .setSiteName("HaxeFolio Sample")
            .setDefaultTitleText("{{haxefolio.sample.default_title}}")
            .addLocale("en", "English")
            .addLocale("ru", "Русский")
            .addPage("home", params -> new HomePage(), true)
            .addPage("about", params -> new AboutPage())
            .addPage("text-demo", params -> new TextDemoPage())
            .addLeftMenubarItem(NormalMenu("navigation", []))
            .addNormalMenuItem("navigation", "home", NavigateTo(() -> "home"))
            .addNormalMenuItem("navigation", "about", NavigateTo(() -> "about"))
            .addLeftMenubarItem(NormalMenu("text-demo", [], "{{haxefolio.sample.menu_label_with_param, 2}}"))
            .addNormalMenuItem("text-demo", "open", NavigateTo(() -> "text-demo"), null, "Open")
            .addNormalMenuItem("text-demo", "reset-labels", Execute(resetLabels), null, "{{haxefolio.sample.reset_labels_label}}")
            .addLeftMenubarItem(NormalMenu("overlay-demo", []))
            .addNormalMenuItem("overlay-demo", "plain", Execute(showPlainOverlay))
            .addNormalMenuItem("overlay-demo", "dismissible", Execute(showDismissibleOverlay))
            .addNormalMenuItem("overlay-demo", "no-close-button", Execute(showNoCloseButtonOverlay))
            .addNormalMenuItem("overlay-demo", "mobile-variant", Execute(showMobileVariantOverlay))
            .addNormalMenuItem("overlay-demo", "explicit-size", Execute(showExplicitSizeOverlay))
            .addRightMenubarItem(Widget(settingsWidget, true))
            .setLanguagePreference(SamplePreferences.language)
            .buildConfig();

        HaxeFolioApp.init(config);
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
        A plain custom overlay - the core claim this sample exists to verify: arbitrary
        framework-user content works through the same modal/sidebar mechanism the preference
        window uses, entirely CSS-defaulted (no width/height/closeButtonSize given).
    */
    private static function showPlainOverlay():Void
        HaxeFolioApp.showOverlay("custom-plain", _ -> CustomOverlayContent.buildPlain());

    /*
        Its own "Save & Close" button closes it via the dismiss callback its factory received,
        alongside the regular close button.
    */
    private static function showDismissibleOverlay():Void
        HaxeFolioApp.showOverlay("custom-dismissible", CustomOverlayContent.buildDismissible);

    /*
        showCloseButton: false - the content's own Close button (wired to the same dismiss
        callback) is the only way to close this one.
    */
    private static function showNoCloseButtonOverlay():Void
        HaxeFolioApp.showOverlay("custom-no-close-button", CustomOverlayContent.buildNoCloseButton, null, null, null, null, null, false);

    /*
        mobileContentFactory renders a genuinely different component tree on the mobile sidebar
        presentation than contentFactory renders on the desktop modal - resize across
        menuCollapseWidth with this overlay open to see both.
    */
    private static function showMobileVariantOverlay():Void
        HaxeFolioApp.showOverlay("custom-mobile-variant", _ -> CustomOverlayContent.buildDesktopVariant(), null, null, null, null, null, true, _ -> CustomOverlayContent.buildMobileVariant());

    /*
        Explicit width/height/closeButtonSize/insets, overriding whatever CSS would otherwise
        apply to this overlay's modal presentation.
    */
    private static function showExplicitSizeOverlay():Void
        HaxeFolioApp.showOverlay("custom-explicit-size", _ -> CustomOverlayContent.buildExplicitSize(), 320, 220, 24, 16, 16);
}
