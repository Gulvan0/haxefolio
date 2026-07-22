package haxefolio;

import haxefolio.menu.MenuBarConfig;
import haxefolio.menu.SidebarGroup;
import haxefolio.preferences.Preference;
import haxefolio.preferences.PreferenceRegistry;

typedef HaxeFolioConfig = {
    /**
        App identifier, used to namespace LocalStorage preference entries (see
        `preferences.StorageBackend`) and wherever the current site needs to be distinguished from
        other HaxeFolio-based sites.
    **/
    appSlug:String,

    /**
        Path to the icon used for the `HaxeUIApp`/browser tab. Distinct from the favicon swapping
        `PageBase.startBlink` does for notifications.
    **/
    appIcon:String,

    /**
        Literal (not localized) text of the `SiteName` menu bar item's label.
    **/
    siteName:String,

    /**
        The mobile/desktop width breakpoint below which the menu bar collapses to just the
        hamburger button plus persistent widgets. Defaults to 900.
    **/
    ?menuCollapseWidth:Int,

    /**
        The app's page definitions, checked top-to-bottom to resolve a URL path - see
        `PageDefinition`.
    **/
    pages:Array<PageDefinition>,

    /**
        Left/right menu bar item definitions - see `MenuBarConfig`/`MenuBarItem`.
    **/
    menubar:MenuBarConfig,

    /**
        Additional side-bar-only groups, appended after the groups mirroring the menu bar's own
        `NormalMenu`s - see `SidebarGroup`.
    **/
    ?sidebarExtras:Array<SidebarGroup>,

    /**
        Locale key (resolved with no params) used as the tab title fallback for pages that never
        call `PageBase.setTitle`. If omitted, the literal `siteName` is used instead.
    **/
    ?defaultTitleKey:String,

    /**
        Maps each locale id the app provides strings for (the `id` declared under `<locales>` in
        the app's `module.xml`) to a human-readable display name, e.g. `"en" => "English"`. Only
        the keys are consulted by the framework itself, to validate the detected system locale
        against; the display names are for the framework user's own use, e.g. as option labels for
        a language preference. Defaults to `["en" => "English"]`.
    **/
    ?supportedLocales:Map<String, String>,

    /**
        Maps a preference tab's slug (the `tabId` passed to
        `PreferenceRegistry.toggle`/`option`/`locale`) to an icon asset path, shown next to that
        tab's label in both the desktop modal and mobile sidebar presentations. Tabs with no entry
        here are shown without an icon.
    **/
    ?preferenceTabIcons:Map<String, String>,

    /**
        Kept only for its class identity, never read as a value - this is what keeps its static
        field initializers (the `PreferenceRegistry.toggle`/`option`/`locale` calls) reachable for
        Haxe's dead code elimination, and guarantees they've already run by the time
        `HaxeFolioApp.init` looks at any declared preference, including `languagePreference` below.
    **/
    preferences:Class<PreferenceRegistry>,

    /**
        The `Preference<String>` returned by a `PreferenceRegistry.locale(...)` call in the
        framework user's `PreferenceRegistry` subclass, if one was declared. `HaxeFolioApp`
        finalizes its admissible values against `supportedLocales` and wires it to `LocaleManager`
        and to the active page's title/blink text automatically. Omit if the app doesn't offer a
        language preference.
    **/
    ?languagePreference:Preference<String>
}
