package haxefolio;

import haxe.ui.HaxeUIApp;
import haxe.ui.Toolkit;
import haxe.ui.locale.LocaleManager;
import haxe.ui.focus.FocusManager;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxefolio.appearance.AppearanceContext;
import haxefolio.appearance.AppearanceOverrides;
import js.Browser;
import morestd.Throttler;
import haxefolio.menu.DropdownWidget;
import haxefolio.menu.MenuFacade;
import haxefolio.menu.SideBarController;
import haxefolio.menu.builder.MenuBarBuilder;
import haxefolio.menu.builder.MenuBarBuilder.MenuBarBuildResult;
import haxefolio.menu.builder.SideBarBuilder;
import haxefolio.notification.Notification;
import haxefolio.notification.NotificationLayer;
import haxefolio.overlay.EmbeddedOverlay;
import haxefolio.overlay.OverlayContent;
import haxefolio.overlay.OverlayController;
import haxefolio.preferences.PreferenceRegistry;
import haxefolio.preferences.StorageBackend;
import haxefolio.preferences.builder.PreferenceWindowBuilder;
import haxefolio.structure.EdgePanel;
import haxefolio.structure.ScrollArea;
import haxefolio.PageRouter.PageResolution;

using StringTools;

class HaxeFolioApp
{
    /**
        Holds the state passed to `navigateTo` (or later set via `setState`) while a transition is
        in progress or a throttled `setState` write is waiting, since at that point it has not been
        written to `history.state` yet. Otherwise (in particular, right after a plain reload or a
        back/forward navigation), `navigationState` reads the browser-preserved `history.state`
        directly.
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

    private static inline var DEFAULT_LEAVE_CONFIRM_TEXT:String = "Changes you made may not be saved. Leave this page?";

    private static var pendingNavigationState:Dynamic;
    private static var hasPendingNavigationState:Bool = false;
    private static var stateThrottler:Throttler;
    private static var pageEpoch:Int = 0;
    private static var transitionInProgress:Bool = false;
    private static var pendingFragment:Null<String>;

    // The address bar's entry for the current page, to restore it when a back/forward navigation is refused
    private static var committedPath:Null<String>;
    private static var committedState:Dynamic;
    private static var committedFragment:Null<String>;
    private static var config:HaxeFolioConfig;
    private static var pageContainer:Box;
    private static var currentPage:PageBase;
    private static var currentPageScrollArea:ScrollArea;

    /**
        Initializes the framework from `config`: builds the menu bar and side bar, sets up
        routing, preferences and responsivity, then opens the page matching the current URL (or
        the default page if it doesn't resolve to one). Must be called exactly once, after every
        `PreferenceRegistry` subclass the app declares has had its static field initializers run
        (see `HaxeFolioConfig.preferences`).
    **/
    public static function init(config:HaxeFolioConfig):Void
    {
        Toolkit.autoScale = false; // the browser already maps CSS pixels to device pixels
        Toolkit.init();
        AppearanceContext.init(config.appearance);
        FocusManager.instance.enabled = false;
        FocusManager.instance.autoFocus = false;

        var app:HaxeUIApp = new HaxeUIApp();
        app.icon = config.appIcon;

        var supportedLocales:Map<String, String> = config.supportedLocales ?? ["en" => "English"];
        var supportedLocaleCodes:Array<String> = [for (code in supportedLocales.keys()) code];
        var detectedLocale:String = resolveDetectedLocale(supportedLocaleCodes, LocaleManager.instance.language);

        if (config.languagePreference != null)
            config.languagePreference.finalizeAdmissibleValues(supportedLocaleCodes, detectedLocale);

        PageRouter.init(config.pages);
        HaxeFolioApp.config = config;
        stateThrottler = new Throttler(config.stateThrottleMs ?? 1000);

        valueStorage = new StorageBackend(config.appSlug);
        PreferenceRegistry.provideBackend(valueStorage);

        LocaleManager.instance.language = config.languagePreference != null ? config.languagePreference.get() : detectedLocale;

        if (config.languagePreference != null)
            config.languagePreference.onChange(newLocale -> {
                LocaleManager.instance.language = newLocale;

                if (currentPage != null)
                    currentPage.resyncLocalizedText();
            });

        var sideBar:EdgePanel = SideBarBuilder.build(config);

        var menuBarBuildResult:MenuBarBuildResult = MenuBarBuilder.build(config);
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

        var notificationLayer:Component = NotificationLayer.init();

        OverlayController.init([root, sideBar, notificationLayer]);
        SideBarController.init(sideBar, [root, notificationLayer]);

        var menuCollapseWidth:Int = config.menuCollapseWidth ?? 900;
        var debounceMs:Int = config.debounceMs ?? 500;

        ResponsivityController.init(pageContainer, menuBarBuildResult.hamburgerButton, menuBarBuildResult.collapsibleComponents, menuCollapseWidth, config.widthTiers ?? [], debounceMs, (width, height) -> {
            if (currentPage != null)
                currentPage.onResize(currentPageScrollArea.element.clientWidth, currentPageScrollArea.element.clientHeight);

            OverlayController.resize();
            SideBarController.fit();
            NotificationLayer.fit();
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
        Replaces the current page's path in the address bar with `path`, without navigating: the
        page stays as it is, its `navigationState` and fragment are kept, and no back/forward entry
        is added. For a page whose content now lives at another path (a draft that got saved under
        an id). `path` isn't resolved against the registered pages.
    **/
    public static function replacePath(path:String):Void
    {
        PageRouter.replaceUrl(path, navigationState, PageRouter.readFragmentFromUrl());
    }

    /**
        Navigates to the default page (the one registered with `isDefault: true`).
    **/
    public static function navigateToDefault():Void
    {
        openDefaultPage(true);
    }

    /** The path of the default page (the one registered with `isDefault: true`) **/
    public static var defaultPagePath(get, never):String;

    private static function get_defaultPagePath():String
    {
        return PageRouter.defaultPageDefinition.path;
    }

    /**
        The absolute URL that navigating to `path` (with `fragment`) shows in the address bar - for
        a link to a page shared outside the app. `path` isn't resolved against the registered pages.
    **/
    public static function pageUrl(path:String, ?fragment:String):String
    {
        return PageRouter.absoluteUrl(path, fragment);
    }

    /**
        Presents an overlay: a frame holding the regions of the `OverlayContent` that
        `contentFactory` builds, over a scrim covering the whole screen - a centred dialog while
        the breakpoint is expanded, a bottom sheet while it is collapsed. Which one is decided
        internally, once, when `present` is called, and stays fixed for that overlay's lifetime;
        there is deliberately no presentation argument (see `Overlays` in the manual).

        Both presentations are modal: nothing beneath is reachable - by pointer, keyboard or
        assistive technology - until the overlay is gone. It is dismissed by Esc, by the `dismiss`
        handle its factory receives, or by navigating away (which closes it first); nothing else.

        `slug` identifies the overlay for CSS (`#haxefolio-overlay-<slug>-*`) and must be unique
        per call site. `mobileContentFactory`, if given, is used instead of `contentFactory` while
        the breakpoint is collapsed. `appearance` overrides the geometry/emphasis - and adds a
        style class - for this overlay only. `onDismissed` runs once the overlay is entirely gone,
        after the content's own `onDismissed`. A no-op while an overlay is already open or closing.
    **/
    public static function present(slug:String, contentFactory:(Void->Void)->OverlayContent, ?mobileContentFactory:(Void->Void)->OverlayContent, ?appearance:AppearanceOverrides, ?onDismissed:Void->Void):Void
    {
        OverlayController.present(slug, contentFactory, mobileContentFactory, appearance, onDismissed);
    }

    /**
        `present` over the overlay that is open (a picker opened from a form): it stacks on top of
        it, dimming and covering only that overlay - its frame, not the whole screen - or, as a
        sheet, leaving a strip of it visible. Only the topmost overlay reacts to Esc, and
        dismissing an overlay dismisses those above it. A no-op while no overlay is open, or the
        topmost is closing or has the same `slug`.
    **/
    public static function presentOver(slug:String, contentFactory:(Void->Void)->OverlayContent, ?mobileContentFactory:(Void->Void)->OverlayContent, ?appearance:AppearanceOverrides, ?onDismissed:Void->Void):Void
    {
        OverlayController.present(slug, contentFactory, mobileContentFactory, appearance, onDismissed, true);
    }

    /**
        Embeds the regions of the `OverlayContent` that `contentFactory` builds in `into`, as a
        bordered frame of `frameHeight` pixels and the full width of `into` - the region model of
        `present` without a presentation: no scrim, no Esc, nothing made inert, and it neither
        counts as the open overlay nor blocks one.

        `into` must have a width for the frame to resolve against. The host owns the frame's
        height (`frameHeight`, changeable through the returned handle) and its teardown: call the
        handle's `detach()` once done, e.g. from a page's `onClose`. `appearance` overrides the
        geometry/emphasis - and adds a style class - for this embedded content only, as for `present`.

        There is no footer by default, so decide how the content commits (see `Embedded content`
        in the manual).
    **/
    public static function embed(slug:String, contentFactory:Void->OverlayContent, into:Component, frameHeight:Float, ?appearance:AppearanceOverrides):EmbeddedOverlay
    {
        return OverlayController.embed(slug, contentFactory, into, frameHeight, appearance);
    }

    /**
        Shows `content` as a notification: non-blocking, anchored to the bottom of the viewport -
        the bottom-right corner while the breakpoint is expanded, where the content is
        `expandedWidth` pixels wide; the full viewport width minus the margins while it is
        collapsed. Notifications stack upward in the order they were shown, the newest at the
        bottom, and stay until the returned handle's `dismiss()` is called - there is no expiry.

        The framework draws nothing around `content`: its surface, layout and controls are the
        host's, and so is its height, which may change while shown (the stack re-anchors). Like
        the page, notifications are unreachable while an overlay or the side bar is open.
    **/
    public static function notify(content:Component, expandedWidth:Float):Notification
    {
        return NotificationLayer.show(content, expandedWidth);
    }

    /**
        Opens the built-in preference window: an overlay (see `present`) with one tab per
        preference tab and a Reset footer, whose controls apply on change. Customizable through
        `HaxeFolioConfig.preferenceWindowAppearance` and CSS (`#haxefolio-overlay-preference-*`).
    **/
    /**
        Whether `node` is bare background of the open page: it lies inside the page area (not the
        menu bar, an overlay or anything else on `Screen`) and the nearest HaxeUI component it
        belongs to is a pure layout container - a `Box` (`VBox`, `HBox`, the page itself...) or
        the page's scroll area - rather than a control. Lets a page tell a press on empty space
        from a press on something that reacts to it.
    **/
    public static function isPageBackground(node:Null<js.html.Node>):Bool
    {
        if (node == null || pageContainer == null || !pageContainer.element.contains(node))
            return false;

        var component:Component = nearestComponent(node);
        return Std.isOfType(component, Box) || Std.isOfType(component, ScrollArea);
    }

    /*
        The deepest component of the page area whose element contains `node`. Searched from the
        top down: haxeui-html5's own element-to-component map only holds components briefly,
        while they're being created.
    */
    private static function nearestComponent(node:js.html.Node):Component
    {
        var current:Component = pageContainer;
        while (true)
        {
            var child:Null<Component> = Lambda.find(current.childComponents, child -> child.element.contains(node));
            if (child == null)
                return current;
            current = child;
        }
    }

    public static function showPreferences():Void
    {
        present("preference", _ -> PreferenceWindowBuilder.build(config.preferenceTabIcons), null, config.preferenceWindowAppearance);
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
        committedFragment = fragment;

        if (keepInHistory)
            PageRouter.pushUrl(PageRouter.readPathFromUrl(), navigationState, fragment);
        else
            PageRouter.replaceUrl(PageRouter.readPathFromUrl(), navigationState, fragment);
    }

    /**
        Replaces the `navigationState` of the current page in place, without a full navigation -
        the path and fragment are left untouched. Like `navigateTo`'s `state`, it must be plain,
        structured-clone-compatible data. `navigationState` reflects the new value immediately,
        but the write to the browser history is throttled (`HaxeFolioConfig.stateThrottleMs`,
        1000 by default) since browsers rate-limit `history.replaceState`/`pushState`: calls in
        quick succession collapse into one write of the latest state. By default the write uses
        `history.replaceState`; pass `keepInHistory: true` to use `history.pushState` instead.
        A write still waiting when the user navigates to another page is dropped. Safe to call
        from a page's own `init`, in which case the enclosing transition writes the state
        unthrottled.
    **/
    public static function setState(?state:Dynamic, keepInHistory:Bool = false):Void
    {
        pendingNavigationState = state;
        hasPendingNavigationState = true;

        if (transitionInProgress)
            return;

        var epoch:Int = pageEpoch;

        stateThrottler.run(() -> {
            if (epoch != pageEpoch || !hasPendingNavigationState)
                return;

            var path:Null<String> = PageRouter.readPathFromUrl();
            var fragment:Null<String> = PageRouter.readFragmentFromUrl();

            if (keepInHistory)
                PageRouter.pushUrl(path, pendingNavigationState, fragment);
            else
                PageRouter.replaceUrl(path, pendingNavigationState, fragment);

            committedState = pendingNavigationState;
            pendingNavigationState = null;
            hasPendingNavigationState = false;
        });
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

    /*
        Asks the current page whether it may be left and, if it objects, the user. A refused
        back/forward navigation has already changed the address bar, so the current page's entry
        is pushed back over it.
    */
    private static function mayLeaveCurrentPage(isExplicitNavigation:Bool):Bool
    {
        if (currentPage == null || currentPage.canLeave())
            return true;

        var text:String = LocaleUtils.resolveText(config.leaveConfirmText ?? DEFAULT_LEAVE_CONFIRM_TEXT);

        if (Browser.window.confirm(text))
            return true;

        if (!isExplicitNavigation)
            PageRouter.pushUrl(committedPath, committedState, committedFragment);

        return false;
    }

    private static function openPath(path:String, isExplicitNavigation:Bool, ?state:Dynamic, ?fragment:String):Void
    {
        if (!mayLeaveCurrentPage(isExplicitNavigation))
            return;

        var resolution:Null<PageResolution> = PageRouter.resolve(path);

        if (resolution != null)
        {
            beginTransition(isExplicitNavigation ? state : Browser.window.history.state, fragment); // a reload or back/forward keeps the entry's own state

            try
            {
                switchToPage(resolution.definition, resolution.params);

                if (isExplicitNavigation)
                    PageRouter.pushUrl(path, pendingNavigationState, pendingFragment);

                endTransition();
                return;
            }
            catch (e:Dynamic)
            {
                endTransition();

                if (resolution.definition == PageRouter.defaultPageDefinition)
                    throw e;
            }
        }

        openDefaultPage(isExplicitNavigation);
    }

    private static function openDefaultPage(isExplicitNavigation:Bool):Void
    {
        if (!mayLeaveCurrentPage(isExplicitNavigation))
            return;

        beginTransition(null, null);

        try
        {
            switchToPage(PageRouter.defaultPageDefinition, []);
        }
        catch (e:Dynamic)
        {
            endTransition();
            throw e;
        }

        if (isExplicitNavigation)
            PageRouter.pushUrl(PageRouter.defaultPageDefinition.path, pendingNavigationState, pendingFragment)
        else
            PageRouter.replaceUrl(PageRouter.defaultPageDefinition.path, pendingNavigationState, pendingFragment);

        endTransition();
    }

    private static function beginTransition(state:Dynamic, fragment:Null<String>):Void
    {
        transitionInProgress = true;
        pageEpoch++;
        pendingNavigationState = state;
        hasPendingNavigationState = true;
        pendingFragment = fragment;
    }

    private static function endTransition():Void
    {
        committedPath = PageRouter.readPathFromUrl();
        committedState = Browser.window.history.state;
        committedFragment = PageRouter.readFragmentFromUrl();
        transitionInProgress = false;
        pendingNavigationState = null;
        hasPendingNavigationState = false;
        pendingFragment = null;
    }

    private static function switchToPage(definition:PageDefinition, params:Map<String, String>):Void
    {
        // an open overlay belongs to the page it was opened over; don't leave it dangling over the next one
        OverlayController.dismissIfOpen();
        SideBarController.close();
        DropdownWidget.closeOpen();

        var page:PageBase = definition.factory(params);

        if (currentPage != null)
        {
            currentPage.finalizeClose();
            pageContainer.removeComponent(currentPageScrollArea, true);
            currentPage = null;
            currentPageScrollArea = null;
        }

        /*
            Every page scrolls vertically inside its own ScrollArea (a fresh one per navigation,
            since pages are never reused), so a page taller than the container scrolls while the
            menu bar stays put.
        */
        page.percentHeight = null;

        // the inset lives inside the scrolling area, so the area itself (and its scrollbar) reaches the window edge
        var inset:Box = new Box();
        inset.percentWidth = 100;
        inset.addClass("haxefolio-page-container-inset");
        inset.addComponent(page);

        var scrollArea:ScrollArea = new ScrollArea(inset);
        scrollArea.percentHeight = 100;
        pageContainer.addComponent(scrollArea);

        try
        {
            page.init();
        }
        catch (e:Dynamic)
        {
            pageContainer.removeComponent(scrollArea, true);
            throw e;
        }

        if (!page.titleWasSet)
            Browser.document.title = LocaleUtils.resolveText(config.defaultTitleText ?? config.siteName);

        currentPage = page;
        currentPageScrollArea = scrollArea;
    }

    private static function get_navigationState():Dynamic
    {
        return hasPendingNavigationState ? pendingNavigationState : Browser.window.history.state;
    }

    private static function get_fragment():Null<String>
    {
        return pendingFragment ?? PageRouter.readFragmentFromUrl();
    }
}
