package haxefolio;

import haxe.ui.HaxeUIApp;
import haxe.ui.Toolkit;
import haxe.ui.locale.LocaleManager;
import haxe.ui.containers.Box;
import haxe.ui.containers.SideBar;
import haxe.ui.containers.VBox;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.core.Screen;
import js.Browser;
import haxefolio.menu.MenuFacade;
import haxefolio.menu.builder.MenuBarBuilder;
import haxefolio.menu.builder.MenuBarBuilder.MenuBarBuildResult;
import haxefolio.menu.builder.SideBarBuilder;
import haxefolio.overlay.OverlayContent;
import haxefolio.overlay.builder.ModalOverlay;
import haxefolio.overlay.builder.SideBarOverlay;
import haxefolio.preferences.PreferenceRegistry;
import haxefolio.preferences.StorageBackend;
import haxefolio.preferences.builder.PreferenceWindowBuilder;
import haxefolio.PageRouter.PageResolution;

using StringTools;

class HaxeFolioApp
{
    /**
        Holds the state passed to `navigateTo` while a transition is in progress, since at that
        point it has not been pushed to `history.state` yet. Outside of an in-progress transition
        (in particular, right after a plain reload or a back/forward navigation), this is null and
        `navigationState` instead reads the browser-preserved `history.state` directly.
    **/
    public static var navigationState(get, never):Dynamic;

    /**
        Mirrors `navigationState`, but for the URL fragment: holds the fragment passed to
        `navigateTo` (or later overridden via `setFragment`) while a transition is in progress,
        since at that point it has not been written into `location.hash` yet. Outside of an
        in-progress transition, this is null and `fragment` instead reads `location.hash` directly.
    **/
    public static var fragment(get, never):Null<String>;

    /**
        App-scoped key-value storage. Built over the browser's LocalStorage
    **/
    public static var valueStorage(default, null):StorageBackend;

    private static var pendingNavigationState:Dynamic;
    private static var pendingFragment:Null<String>;
    private static var config:HaxeFolioConfig;
    private static var pageContainer:Box;
    private static var currentPage:PageBase;

    /**
        Initializes the framework from `config`: builds the menu bar and side bar, sets up
        routing, preferences and responsivity, then opens the page matching the current URL (or
        the default page if it doesn't resolve to one). Must be called exactly once, after every
        `PreferenceRegistry` subclass the app declares has had its static field initializers run
        (see `HaxeFolioConfig.preferences`).
    **/
    public static function init(config:HaxeFolioConfig):Void
    {
        Toolkit.init();

        var app:HaxeUIApp = new HaxeUIApp();
        app.icon = config.appIcon;

        var supportedLocales:Map<String, String> = config.supportedLocales ?? ["en" => "English"];
        var supportedLocaleCodes:Array<String> = [for (code in supportedLocales.keys()) code];
        var detectedLocale:String = resolveDetectedLocale(supportedLocaleCodes, LocaleManager.instance.language);

        if (config.languagePreference != null)
            config.languagePreference.finalizeAdmissibleValues(supportedLocaleCodes, detectedLocale);

        PageRouter.init(config.pages);
        HaxeFolioApp.config = config;

        valueStorage = new StorageBackend(config.appSlug);
        PreferenceRegistry.provideBackend(valueStorage);

        LocaleManager.instance.language = config.languagePreference != null ? config.languagePreference.get() : detectedLocale;

        if (config.languagePreference != null)
            config.languagePreference.onChange(newLocale ->
            {
                LocaleManager.instance.language = newLocale;

                if (currentPage != null)
                    currentPage.resyncLocalizedText();
            });

        var sideBar:SideBar = SideBarBuilder.build(config);

        var menuBarBuildResult:MenuBarBuildResult = MenuBarBuilder.build(config, sideBar);
        var menuBar:MenuBar = menuBarBuildResult.menuBar;

        MenuFacade.init(menuBar, sideBar);

        pageContainer = new Box();
        pageContainer.percentWidth = 100;
        pageContainer.percentHeight = 100;
        pageContainer.id = "haxefolio-page-container";
        pageContainer.addClass("haxefolio-page-container");

        var root:VBox = new VBox();
        root.percentWidth = 100;
        root.percentHeight = 100;
        root.verticalSpacing = 0;
        root.addComponent(menuBar);
        root.addComponent(pageContainer);

        Screen.instance.addComponent(root);
        Screen.instance.addComponent(sideBar);

        var menuCollapseWidth:Int = config.menuCollapseWidth ?? 900;
        var debounceMs:Int = config.debounceMs ?? 500;

        ResponsivityController.init(pageContainer, menuBarBuildResult.hamburgerButton, menuBarBuildResult.collapsibleComponents, menuCollapseWidth, debounceMs, (width, height) ->
        {
            if (currentPage != null)
                currentPage.onResize(width, height);
        });

        Browser.window.addEventListener("popstate", _ -> openFromCurrentUrl());

        openFromCurrentUrl();
    }

    /**
        Navigates to `path`, resolved against the registered `PageDefinition`s; redirects to the
        default page if it doesn't resolve to one, or if the resolved page's factory or `init`
        throws. Callable from anywhere - page lifecycle methods, menu callbacks, or any other user
        code. `state` and `fragment` are optional and retrievable from the destination page (from
        its constructor, `init`, or later) via `navigationState`/`fragment`.
    **/
    public static function navigateTo(path:String, ?state:Dynamic, ?fragment:String):Void
    {
        openPath(path, true, state, fragment);
    }

    /**
        Navigates to the default page (the one registered with `isDefault: true`).
    **/
    public static function navigateToDefault():Void
    {
        openDefaultPage(true);
    }

    /*
        Whether an overlay (built-in preference window or a framework user's own, either
        presentation) is currently open, guarding `showOverlay` against re-entrant calls - e.g. a
        user double-pressing the button that triggers one - which would otherwise build a second
        overlay before the first one is gone.
    */
    private static var overlayOpen:Bool = false;

    /*
        The dismiss closure returned by whichever presentation (ModalOverlay/SideBarOverlay) is
        currently showing the open overlay, if any - null whenever overlayOpen is false. Held here
        so switchToPage's navigation guard, and a factory's own `dismiss` callback argument (see
        showOverlay), both have a way to close the current overlay without knowing which
        presentation built it.
    */
    private static var currentOverlayDismiss:Null<Void->Void> = null;

    /**
        Shows an overlay - the generic, dismissible modal/sidebar mechanism the built-in preference
        window (`showPreferences`) is itself the first consumer of. Picks a presentation
        appropriate to the current layout mode: a bottom `SideBar` overlay covering the whole
        viewport while the menu bar is collapsed (mobile, fully exclusive - nothing beneath it is
        reachable while it's open, opening or closing), or a centered, non-blocking modal scoped to
        the page container otherwise (desktop - the rest of the app, menu bar included, stays fully
        interactive). Neither touches the current page. A no-op while an overlay - built-in or
        custom - is already open or in the middle of closing; navigating away while one is open
        force-closes it first (see `switchToPage`).

        `slug` identifies this overlay for CSS purposes (`#haxefolio-overlay-<slug>-*`, see
        `Styling` in the manual) and must be unique across every `showOverlay` call site in the
        app, including the built-in preference window's own `"preference"`.

        `contentFactory` is only invoked if the call isn't a no-op, and receives a `dismiss`
        callback the built content can call to close the overlay itself (e.g. a "Save & Close"
        button) - this is the only way to close an overlay shown with `showCloseButton: false`.
        `mobileContentFactory`, if given, is used instead of `contentFactory` for the mobile
        `SideBar` presentation specifically, letting a framework user supply genuinely different
        component trees for the two presentations; omitted, `contentFactory` is reused for both,
        which is what `showPreferences` itself does.

        `width`/`height` apply to the desktop modal presentation only (ignored for the mobile
        sidebar, which is always full-viewport); together with `closeButtonSize`/
        `closeButtonInsetX`/`closeButtonInsetY`, they're inline overrides applied on top of
        whatever the shipped/framework-user CSS defaults for this overlay are (see `Styling`) -
        omit any of them (`null`) to leave that value to CSS entirely. `showCloseButton: false`
        omits the close button entirely (not just hides it) from whichever presentation is shown.
    **/
    public static function showOverlay(slug:String, contentFactory:(Void->Void)->OverlayContent, ?width:Int, ?height:Int, ?closeButtonSize:Int, ?closeButtonInsetX:Int, ?closeButtonInsetY:Int, showCloseButton:Bool = true, ?mobileContentFactory:(Void->Void)->OverlayContent, ?onDismissed:Void->Void):Void
    {
        if (overlayOpen)
            return;

        overlayOpen = true;

        function onOverlayDismissed():Void
        {
            overlayOpen = false;
            currentOverlayDismiss = null;

            if (onDismissed != null)
                onDismissed();
        }

        var activeFactory:(Void->Void)->OverlayContent = (ResponsivityController.isCollapsed && mobileContentFactory != null) ? mobileContentFactory : contentFactory;
        var content:OverlayContent = activeFactory(() -> currentOverlayDismiss());

        if (ResponsivityController.isCollapsed)
            currentOverlayDismiss = SideBarOverlay.show(slug, content, showCloseButton, closeButtonSize, closeButtonInsetX, closeButtonInsetY, onOverlayDismissed);
        else
            currentOverlayDismiss = ModalOverlay.show(slug, pageContainer, content, width, height, showCloseButton, closeButtonSize, closeButtonInsetX, closeButtonInsetY, onOverlayDismissed);
    }

    /**
        Opens the built-in preference panel. Built on `showOverlay` with slug `"preference"` - see
        its doc comment for the presentation/dismissal/no-op behavior this inherits, including that
        navigating away while the panel is open closes it first.
    **/
    public static function showPreferences():Void
    {
        var tabIcons:Map<String, String> = config.preferenceTabIcons ?? [];

        showOverlay("preference", _ -> PreferenceWindowBuilder.build(tabIcons));
    }

    /**
        Updates the URL fragment of the current page in place, without a full navigation - the
        path and `navigationState` are left untouched. By default this uses
        `history.replaceState` (the new fragment does not get its own back/forward entry); pass
        `keepInHistory: true` to use `history.pushState` instead. Safe to call from a page's own
        `init` (in which case it overrides whatever fragment `navigateTo` was originally given,
        once the enclosing transition writes its own URL) or at any later point in the page's
        lifetime.
    **/
    public static function setFragment(?fragment:String, keepInHistory:Bool = false):Void
    {
        pendingFragment = fragment;

        if (keepInHistory)
            PageRouter.pushUrl(PageRouter.readPathFromUrl(), navigationState, fragment);
        else
            PageRouter.replaceUrl(PageRouter.readPathFromUrl(), navigationState, fragment);
    }

    /*
        Resolves the system-detected locale against the app's declared supportedLocales, returning
        one of their exact codes (normalized, and matched by base language if needed, e.g. a
        detected "en-GB" resolves to a declared "en") so the result is always a valid admissible
        value for the language preference. Falls back to "en" (or, if that itself isn't declared,
        to the first declared locale) when nothing matches.
    */
    private static function resolveDetectedLocale(supportedLocaleCodes:Array<String>, systemLocale:String):String
    {
        var normalized:String = systemLocale.replace("-", "_");

        if (supportedLocaleCodes.indexOf(normalized) != -1)
            return normalized;

        var baseLanguage:String = normalized.split("_")[0];

        if (supportedLocaleCodes.indexOf(baseLanguage) != -1)
            return baseLanguage;

        return supportedLocaleCodes.indexOf("en") != -1 ? "en" : supportedLocaleCodes[0];
    }

    private static function openFromCurrentUrl():Void
    {
        var path:Null<String> = PageRouter.readPathFromUrl();

        if (path == null)
        {
            openDefaultPage(false);
            return;
        }

        openPath(path, false);
    }

    private static function openPath(path:String, isExplicitNavigation:Bool, ?state:Dynamic, ?fragment:String):Void
    {
        var resolution:Null<PageResolution> = PageRouter.resolve(path);

        if (resolution != null)
        {
            pendingNavigationState = state;
            pendingFragment = fragment;

            try
            {
                switchToPage(resolution.definition, resolution.params);

                if (isExplicitNavigation)
                    PageRouter.pushUrl(path, state, pendingFragment);

                pendingNavigationState = null;
                pendingFragment = null;
                return;
            }
            catch (e:Dynamic)
            {
                pendingNavigationState = null;
                pendingFragment = null;

                if (resolution.definition == PageRouter.defaultPageDefinition)
                    throw e;
            }
        }

        openDefaultPage(isExplicitNavigation);
    }

    private static function openDefaultPage(isExplicitNavigation:Bool):Void
    {
        switchToPage(PageRouter.defaultPageDefinition, []);

        if (isExplicitNavigation)
            PageRouter.pushUrl(PageRouter.defaultPageDefinition.path, null, pendingFragment)
        else
            PageRouter.replaceUrl(PageRouter.defaultPageDefinition.path, null, pendingFragment);

        pendingFragment = null;
    }

    private static function switchToPage(definition:PageDefinition, params:Map<String, String>):Void
    {
        /*
            The desktop modal presentation is deliberately non-blocking (see ModalOverlay), so menu
            bar navigation genuinely works while one is open - without this, a modal (or the mobile
            sidebar) would otherwise be left dangling over whatever new page gets swapped in below.
            Force-dismissing first keeps an open overlay and a navigation from silently coexisting.
        */
        if (overlayOpen)
            currentOverlayDismiss();

        var page:PageBase = definition.factory(params);

        if (currentPage != null)
        {
            currentPage.finalizeClose();
            pageContainer.removeComponent(currentPage, true);
            currentPage = null;
        }

        pageContainer.addComponent(page);

        try
        {
            page.init();
        }
        catch (e:Dynamic)
        {
            pageContainer.removeComponent(page, true);
            throw e;
        }

        if (!page.titleWasSet)
            Browser.document.title = LocaleUtils.resolveText(config.defaultTitleText ?? config.siteName);

        currentPage = page;
    }

    private static function get_navigationState():Dynamic
    {
        return pendingNavigationState ?? Browser.window.history.state;
    }

    private static function get_fragment():Null<String>
    {
        return pendingFragment ?? PageRouter.readFragmentFromUrl();
    }
}
