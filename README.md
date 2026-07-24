# HaxeFolio Manual

HaxeFolio is a framework for building a HaxeUI HTML5 single-page web app. It lays out a menu bar and a page container, and the app is composed of "pages" swapped in and out of that container as the URL changes - from a general web technology perspective the site is still a single HTML page, so HaxeFolio's own notion of "page" (a HaxeUI component, not a document) is worth keeping in mind throughout this manual. HaxeFolio is built over the HaxeUI library and targets HTML5.

## Getting started

At minimum, an app registers its pages and menu, and calls `HaxeFolioApp.init`. For example:

```haxe
class Main
{
    public static function main():Void
    {
        var settingsWidget:Label = new Label();
        settingsWidget.text = "⚙";
        settingsWidget.onClick = _ -> HaxeFolioApp.showPreferences();

        var config:HaxeFolioConfig = HaxeFolioConfigBuilder.init("my-app", Preferences)
            .setAppIcon("assets/favicons/normal.png")
            .setSiteName("My App")
            .addPage("home", params -> new HomePage(), true)
            .addPage("user/{login}", params -> new UserPage(params["login"]))
            .addLeftMenubarItem(SiteName)
            .addLeftMenubarItem(NormalMenu("navigation", []))
            .addNormalMenuItem("navigation", "home", NavigateTo(() -> "home"))
            .addRightMenubarItem(Widget(settingsWidget, true))
            .setLanguagePreference(Preferences.language)
            .buildConfig();

        HaxeFolioApp.init(config);
    }
}
```

The rest of this manual covers each piece of this in turn: pages and navigation, the menu bar and side bar, responsivity, preferences, and finally the full `HaxeFolioConfig`/`HaxeFolioConfigBuilder` reference these all feed into.

## Pages

### Defining a page

Each page is a HaxeUI component extending `PageBase` (provided by the framework), implemented entirely by the framework user - pages are expected to make up nearly all of an app's own code, outside HaxeFolio itself. A page's constructor may take any signature; the framework never calls it directly (see `Registering pages` below).

`PageBase` gives every page three lifecycle methods, all optional to override:

```haxe
class GamePage extends PageBase
{
    private override function init():Void { ... }
    private override function onResize(width:Float, height:Float):Void { ... }
    private override function onClose():Void { ... }
}
```

- `init` runs once the page has been added to the container - the place for a page's own setup, rather than its constructor. May throw; `HaxeFolioApp.navigateTo` may also be called from here to redirect elsewhere before the page finishes opening.
- `onResize(width, height)` runs whenever the page container's size changes, debounced (see `Responsivity`), with the container's new pixel dimensions.
- `onClose` runs right before the page is torn down and the user is navigated away - the place for cleanup such as detaching preference `onChange` handlers (see `Preferences`) or cancelling pending requests. Calling `navigateTo` from here is not supported.

If a page's factory (see below) or `init` throws, the framework redirects to the default page instead - except when the default page's own factory/`init` is what throws, in which case the exception is left uncaught.

Each page is isolated: nothing a page does affects any other page. Pages are also never reused - navigating away destroys the current page for good, and navigating back to the "same" page later creates a fresh instance.

### Registering pages

Pages are registered in `HaxeFolioConfig.pages`, an array of:

```haxe
typedef PageDefinition = {
    path:String,
    factory:Map<String, String>->PageBase,
    ?isDefault:Bool
}
```

- `path` is a URL path template, e.g. `"user/{login}"` - segments enclosed in `{}` are parameters, always resolved as strings. Templates are checked top-to-bottom; the first one that matches wins.
- `factory` builds the page from its parsed path parameters (an empty map if the path has none). This, not the page's constructor, is what the framework actually calls on navigation - it's up to `factory` to forward the right arguments to the constructor, e.g. `params -> new UserPage(params["login"], Std.parseInt(params["version"]))` for a `"user/{login}/{version}"` template. If `factory` throws, the user is redirected to the default page.
- `isDefault` marks the page opened when a URL doesn't resolve to any registered page, or when the site name is clicked (see `Menu and side bar`). Exactly one page must set this to `true`, and that page's `path` must not contain parameters - both are enforced at `HaxeFolioApp.init` time.

### Navigation

Navigating between pages is done by calling `HaxeFolioApp.navigateTo(path)` from anywhere - a page's own lifecycle methods, a menu callback, or any other user code - where `path` is matched against the registered templates above. `HaxeFolioApp.navigateToDefault()` is a shorthand for navigating to the default page specifically, without needing to know or hardcode its path.

Every navigation updates the URL to `https://<host>:<port>/?p=<path>`, pushed onto the browser's history so back/forward navigation works as expected. Loading the site with no `p` parameter, an unresolvable one, or navigating back/forward to one, all fall back to the default page (updating the URL to match it). Since `.../?p=user/alice` and `.../?p=user/bob` are different paths, moving between them via back/forward destroys and recreates the page just like an explicit `navigateTo` call would.

#### Passing state and a fragment

Sometimes a transition needs to carry data that doesn't belong in the path - for example, a game page's "Analyze" button opening an analysis board already preloaded with that game's move list. `navigateTo` takes two further optional arguments for this:

```haxe
HaxeFolioApp.navigateTo(path:String, ?state:Dynamic, ?fragment:String):Void
```

`state` is retrievable from the destination page (its constructor, `init`, or later) via `HaxeFolioApp.navigationState`. It rides on the browser's own `history.pushState`, so - unlike path params - it survives a plain reload or back/forward navigation for that entry, browser-permitting. Two consequences follow:

- it must be plain, structured-clone-compatible data (an anonymous structure, array, or primitive - not a live class instance, since a structured clone only keeps own properties, not the prototype or methods; a page needing a real class instance should reconstruct it from the plain data itself, the same way `params` above is already turned into typed constructor arguments);
- it's subject to the size ceiling browsers impose on history state (typically from a few hundred KB up to a couple MB, depending on the browser) - large payloads shouldn't be routed through it.

When no state was ever pushed for a page, `navigationState` is `null`.

`fragment` is the URL fragment (the part after `#`), retrievable the same way via `HaxeFolioApp.fragment`; unlike `state`, it's visible in the URL itself. A page can update it in place afterwards - without a full navigation, leaving the path and `navigationState` untouched - via:

```haxe
HaxeFolioApp.setFragment(?fragment:String, keepInHistory:Bool = false):Void
```

By default this uses `history.replaceState`, so it doesn't create its own back/forward entry; pass `keepInHistory: true` to use `history.pushState` instead, for the rare case where a fragment change (e.g. switching between tabs within a page) should itself be reachable via the back button. Calling `setFragment` from a page's own `init` overrides whatever fragment `navigateTo` was originally given. When no fragment is set for a page, `fragment` is `null`.

### Page title and notifications

`PageBase` exposes three methods for controlling the browser tab title, and blinking it as a notification:

```haxe
private function setTitle(key:String, ?param0:Any, ?param1:Any, ?param2:Any, ?param3:Any):Void
private function startBlink(key:String, ?param0:Any, ?param1:Any, ?param2:Any, ?param3:Any, ?iconHref:String, intervalMs:Int = 1000):Void
private function stopBlink():Void
```

`setTitle` resolves `key` (with up to 4 positional params substituted for `[0]`..`[3]`, per HaxeUI's own `LocaleManager.lookupString` convention) through localization and assigns the result to `document.title`; callable from `init` or any later point (e.g. once data that only becomes available asynchronously has arrived). If a page's `init` completes without ever calling `setTitle`, the framework falls back to `HaxeFolioConfig.defaultTitleKey` (resolved with no params), if given, or else the literal `siteName`.

`startBlink` alternates the tab title between its current value and a localized, parameterized notification text, once every `intervalMs` (1000 by default). Passing `iconHref` swaps the favicon in lockstep - notification icon while showing the notification text, restored otherwise; omit it to blink only the title. It can only be called after `setTitle` (throws otherwise), and replaces any already-active blink for the page rather than stacking. `stopBlink` restores the pre-blink title/favicon; it's a no-op if nothing is blinking, and the framework also calls it automatically whenever a page is torn down, so forgetting to call it isn't a way to leak a blink into the next page:

```haxe
simulateChallengeButton.onClick = _ -> startBlink("page.home.notification.challenge", 1, null, null, null, NOTIFICATION_ICON);
```

If the app declares a language preference (see `Preferences`) and wires it into `HaxeFolioConfig.languagePreference`, title/blink text stays in sync with it automatically - the framework re-resolves the active page's title/blink text whenever that preference changes, the same way `{{key}}`-bound component text elsewhere refreshes via HaxeUI's own locale-change mechanism. Apps that don't declare a language preference get no such refresh, since nothing else changes the active locale at runtime.

The blinking itself (the timer, the title/favicon swap) is implemented by `haxefolio.browser.Blinker`/`Favicon`, bundled utilities with no dependency on the rest of HaxeFolio, HaxeUI, or locale - usable directly in any HTML5 Haxe app that already has HaxeFolio as a dependency. `PageBase.startBlink`/`stopBlink` are a thin, localization-aware convenience layer on top of them. Deciding *when* to call them (e.g. reacting to `document.visibilitychange`/`document.hidden` to detect the user being away from the tab) is left entirely to the framework user's own code.

## Menu and side bar

The top of the app is a menu bar (`haxe.ui.containers.menus.MenuBar`); a side bar (`haxe.ui.containers.SideBar`, hidden until opened) mirrors it for narrow screens. Both are built from the same `HaxeFolioConfig.menubar`/`sidebarExtras` configuration.

### Menu bar

The menu bar can hold four kinds of items, assembled into `left`/`right` groups (`HaxeFolioConfig.menubar.left`/`.right`, each an `Array<MenuBarItem>` in layout order):

```haxe
enum MenuBarItem
{
    SiteName;
    NormalMenu(slug:String, items:Array<MenuItemDefinition>);
    Widget(component:Component, ?persistent:Bool);
}
```

- **`SiteName`** - a label showing `HaxeFolioConfig.siteName` (a literal string, not localized); navigates to the default page when clicked.
- **`NormalMenu(slug, items)`** - an ordinary dropdown menu. Each `MenuItemDefinition` is `{slug, action, ?icon}`, where `action` is:

  ```haxe
  enum MenuAction
  {
      NavigateTo(pathFactory:Void->String);
      Execute(fn:Void->Void);
  }
  ```

  `NavigateTo` goes through `HaxeFolioApp.navigateTo` just like any other navigation; `Execute` runs an arbitrary function, which may itself call `navigateTo` if it needs to combine navigation with something `NavigateTo` alone doesn't cover (e.g. passing `state`).
- **`Widget(component, ?persistent)`** - a custom component wrapped in its own menu, e.g. the settings button shown in `Getting started`.

Additionally, a hamburger button is always present as the menu bar's leftmost child - hidden by default, shown once the menu bar collapses to its mobile layout (see `Responsivity`), at which point clicking it opens the side bar.

### Side bar

The side bar's first row always holds a hamburger button (closes the side bar) and the site name (closes the side bar and navigates to the default page). Below that, every `NormalMenu` from the menu bar is mirrored as a group: a header line with the menu's own label, followed by an indented, clickable line per item - clicking closes the side bar, then runs the same action as the menu bar counterpart.

`HaxeFolioConfig.sidebarExtras` adds further, side-bar-only groups in the same shape:

```haxe
typedef SidebarGroup = {
    slug:String,
    items:Array<MenuItemDefinition>
}
```

Their main use is replicating navigational aspects of non-persistent menu bar `Widget`s - e.g. an "Account" group with "Log in"/"Sign up" entries, standing in for a widget that's hidden once the menu bar collapses.

Every menu/item/group label goes through localization; see `Locale keys` in `Reference` for the exact key convention.

## Responsivity

HaxeFolio reacts to viewport size changes - window resizing on desktop, orientation changes on mobile - resizing the menu bar and notifying the active page, debounced so a drag-resize doesn't trigger continuous work.

Below `HaxeFolioConfig.menuCollapseWidth` (an author-chosen width past which the menu bar no longer fits everything; defaults to 900), the menu bar hides its `NormalMenu`s and any `Widget` not marked `persistent`, and reveals the hamburger button to reach the side bar instead. Above it, the reverse. Deciding *what* happens at the threshold is HaxeFolio's job; the framework user only supplies the threshold itself and which widgets should stay persistent.

Independently of that threshold, every time the page container is resized, the active page's `onResize(width, height)` is called with its new pixel dimensions (see `Pages`) - overriding it to react to size changes is the framework user's responsibility.

## Preferences

HaxeFolio comes with a preference system: a framework user declares named, typed preferences; their values persist to LocalStorage automatically, are editable by the website user through an auto-generated preference window, and are readable/writable from the app's own code with change notifications.

### Declaring preferences

A framework user declares preferences by extending `PreferenceRegistry` - the class doubles as both the declaration and the typed facade, with no separate config file or init call needed:

```haxe
class Preferences extends PreferenceRegistry
{
    public static final language = PreferenceRegistry.locale("general", "language");
    public static final premoves = PreferenceRegistry.toggle("general", "premoves", false);
    public static final treeview = PreferenceRegistry.option("general", "treeview", ["graph", "outline", "plain"], "graph");
}
```

Calls must be qualified with `PreferenceRegistry.`, even inside the subclass itself - Haxe never resolves inherited static members unqualified, in static field initializers or anywhere else in the subclass body, so a bare `toggle(...)` fails to compile. Even an app with no preferences of its own must still declare an (empty) `PreferenceRegistry` subclass, since `HaxeFolioConfig.preferences` requires one (see `Configuration`).

Three factory methods are available:

- `toggle(tabId, id, default)` - a boolean preference, returns `Preference<Bool>`; rendered as a slider.
- `option(tabId, id, values, default)` - a string-valued preference restricted to `values`, returns `Preference<String>`; rendered as a row of buttons, one per value. Throws if `default` isn't among `values`.
- `locale(tabId, id)` - declares the language preference: an option-shaped preference whose admissible values/default aren't known yet at this point (they depend on `HaxeFolioConfig.supportedLocales`, only available once `HaxeFolioApp.init` runs). At most one may be declared; wiring the returned `Preference<String>` into `HaxeFolioConfig.languagePreference` is what fills those in and hooks the preference up to `LocaleManager` and page titles (see `Configuration` and `Page title and notifications`).

Each call assigns the preference to a named tab (rendered in the preference window, see below), in declaration order; `id` must be unique across the whole subclass - a duplicate id, or a default not among declared values, throws.

### Reading and writing preferences

```haxe
if (Preferences.premoves.get())
    ...
var mode:String = Preferences.treeview.get();
```

`get()` returns the current value, typed, with no cast needed at the call site. Three write paths are available:

- `preference.set(value)` - writes to memory and LocalStorage, then runs every `onChange` handler.
- `preference.setQuiet(value)` - the same write, without running handlers - for programmatic updates that shouldn't trigger reactive code.
- `preference.resetToDefault()` - equivalent to `set(defaultValue)`.

`PreferenceRegistry.resetAll()` calls `resetToDefault` on every declared preference at once (this is what the preference window's reset button calls). LocalStorage is updated on every write regardless of path, whether it originates from the preference window or from the app's own code.

### Reacting to changes

```haxe
var handle:Detachable = Preferences.treeview.onChange(rebuildTreeView);
handle.detach();
```

`onChange` registers a `T->Void` handler that runs on every `set`/`resetToDefault` (not `setQuiet`); multiple handlers may be registered for the same preference. It returns a `Detachable` for later removal. The canonical pattern for a page is registering handlers in `init` and detaching them in `onClose`:

```haxe
class GamePage extends PageBase
{
    private var handles:Array<Detachable>;

    private override function init():Void
        handles = [Preferences.premoves.onChange(updatePremoveIndicator)];

    private override function onClose():Void
        for (h in handles)
            h.detach();
}
```

### Preference storage

Values are persisted to LocalStorage under `<hostname>.<appSlug>.<id>` - namespaced by hostname and `HaxeFolioConfig.appSlug` so multiple HaxeFolio-based sites on the same domain don't collide. On load, each preference takes the value stored under its id, or its declared default if none is stored yet.

Removing a preference from the declaration leaves its LocalStorage entry in place; renaming one is equivalent to removing the old id and adding a new one, so the old value isn't inherited. Preference values aren't readable or writable before `HaxeFolioApp.init` has provided the storage backend.

### Preference window

The preference window's content - tabs and controls - is generated at runtime from what `Preferences` declared, organized as one `TabView` tab per `tabId`, each optionally iconed via `HaxeFolioConfig.preferenceTabIcons` (mapping `tabId` to an icon asset path). Each tab contains a control per preference assigned to it, in declaration order: a slider for `toggle`, a row of buttons (one per admissible value, current one marked active) for `option`/`locale`. Below the tabs, a footer holds a reset button (`PreferenceRegistry.resetAll()`) and a label noting that changes save automatically - there's no separate "OK"/"Apply" step.

A framework user opens the window by calling `HaxeFolioApp.showPreferences()` - typically from a menu bar `Widget`'s `onClick`, or an `Execute` menu action (as in `Getting started` above). Which of two presentations appears depends on the current layout mode: a `SideBar` sliding up from the bottom and covering the entire viewport while the menu bar is collapsed (mobile), or a centered modal over the page container otherwise (desktop), dismissible by clicking its backdrop. Both presentations also offer a dedicated close button, and neither touches the currently open page - it keeps running underneath, untouched by the panel opening or closing. Calling `showPreferences()` again while a panel is already open (or mid-close) is a no-op.

Every displayed string is localized; see `Locale keys` in `Reference`.

## Configuration

`HaxeFolioApp.init(config:HaxeFolioConfig)` wires up everything described above. `config` can be built either as a plain anonymous structure, or via the fluent `HaxeFolioConfigBuilder` shown in `Getting started` - both produce the same `HaxeFolioConfig`.

### HaxeFolioConfig

| Field | Type | Notes |
|---|---|---|
| `appSlug` | `String` | App identifier; namespaces LocalStorage entries (see `Preference storage`) and distinguishes this site from other HaxeFolio-based sites. |
| `appIcon` | `String` | Icon path for the `HaxeUIApp`/browser tab. |
| `siteName` | `String` | Literal (not localized) `SiteName` menu bar item text. |
| `?menuCollapseWidth` | `Int` | Mobile/desktop breakpoint (see `Responsivity`). Defaults to 900. |
| `pages` | `Array<PageDefinition>` | See `Registering pages`. |
| `menubar` | `MenuBarConfig` (`{left, right}`) | See `Menu bar`. |
| `?sidebarExtras` | `Array<SidebarGroup>` | See `Side bar`. |
| `?defaultTitleKey` | `String` | Fallback tab title locale key for pages that never call `setTitle`; falls back further to the literal `siteName` if omitted too. |
| `?supportedLocales` | `Map<String, String>` | Locale id -> display name, e.g. `["en" => "English"]`. Only the keys are consulted by the framework itself (see below); display names are for the app's own use, e.g. as option labels for a language preference. Defaults to `["en" => "English"]`. |
| `?preferenceTabIcons` | `Map<String, String>` | Preference tab id -> icon asset path (see `Preference window`). |
| `preferences` | `Class<PreferenceRegistry>` | The app's `PreferenceRegistry` subclass (see `Declaring preferences`) - referenced only for its class identity, which is what keeps its static field initializers reachable for dead code elimination and guarantees they've run before `init` looks at any declared preference. |
| `?languagePreference` | `Preference<String>` | The `Preference<String>` returned by a `PreferenceRegistry.locale(...)` call, if declared (see `Declaring preferences`). Wiring it in here is what finalizes its admissible values/default from `supportedLocales` and hooks it up to `LocaleManager` and page titles. |

At startup, the auto-detected system locale only becomes the active `LocaleManager.instance.language` if it (or its base language, e.g. `en` for a detected `en_GB`) appears among `supportedLocales`'s keys - otherwise the framework falls back to `en`. This matters because HaxeUI itself ships built-in translations for its own component strings under several locale ids; without the check, a system locale matching one of those (but with no strings of the app's own) would silently resolve every app-specific lookup to the raw key instead of falling back to `en`.

### HaxeFolioConfigBuilder

A fluent, mutating alternative to writing the structure above by hand: `HaxeFolioConfigBuilder.init(appSlug, preferences)` starts a chain, `set*`/`add*` methods (e.g. `setSiteName`, `addPage`, `addNormalMenuItem`, `addSidebarExtraGroupItem`) mutate it and return `this` - `add*` methods appending in call order - and `buildConfig()` terminates the chain, producing the plain `HaxeFolioConfig` (throwing if `setAppIcon`/`setSiteName` were never called). See `Getting started` for a full example.

`addNormalMenuItem(menuSlug, ...)` requires that `menuSlug`'s `NormalMenu` was already added via `addLeftMenubarItem`/`addRightMenubarItem` - it throws otherwise. `addSidebarExtraGroupItem`, by contrast, creates its target group on first use if it doesn't exist yet.

## Styling

Every component HaxeFolio builds carries a `haxefolio-*` CSS class (and often an id) that a framework user's own stylesheet can target to override or complement the framework's defaults, shipped as part of the `haxefolio` module's own theme. A stylesheet registered by the app itself layers on top the same way any HaxeUI theme override does. For example, to recolor the site name label:

```css
.haxefolio-site-name-label {
    color: #205081;
}
```

`HaxeFolioApp.menuBar`/`sideBar` are also exposed as static members, letting a framework user reach into either component and adjust properties directly - once, right after `HaxeFolioApp.init` returns (there's no need to account for redraws, since this only runs once at startup). The preference window has no equivalent static member: unlike the menu bar/side bar, it isn't built once at startup - a fresh instance is built on every `HaxeFolioApp.showPreferences()` call instead, since it must pick one of its two presentations depending on the current layout mode (see `Preference window`). Its supported customization points are instead `HaxeFolioConfig.preferenceTabIcons` and CSS.

See `CSS classes and elements` in `Reference` for the full list of selectors HaxeFolio's own components carry.

## Browser utilities

Bundled alongside the framework, under `haxefolio.browser`, are a handful of small utilities - each wraps a single browser/DOM API, has no dependency on HaxeUI, HaxeFolio's own state, or locale, and is usable directly in any HTML5 Haxe app that already depends on HaxeFolio. `Blinker`/`Favicon` are what `PageBase.startBlink`/`stopBlink`/`setTitle` sit on top of (see `Page title and notifications`); all four classes below are also available for direct use.

### Blinker

```haxe
class Blinker
{
    public static inline var DEFAULT_INTERVAL:Int = 1000;

    public var isActive(get, never):Bool;

    public function new(alternateTitle:String, ?alternateFaviconHref:String, intervalMs:Int = DEFAULT_INTERVAL)
    public function start():Void
    public function stop():Void
}
```

An instance alternates `document.title` between whatever it was when `start()` was called and `alternateTitle`, once every `intervalMs` milliseconds. Passing `alternateFaviconHref` additionally swaps the favicon (via `Favicon.href`, below) in lockstep - shown while the alternate title is showing, restored otherwise; omit it to blink only the title. `start()` captures the current title/favicon as the base to restore to, implicitly stopping any blink already in progress first, so calling it again later re-captures a fresh base rather than reusing a stale one. `stop()` restores the base title/favicon and is a no-op if nothing is active; `isActive` reflects whether a blink is currently running.

### Favicon

```haxe
class Favicon
{
    public static var href(get, set):Null<String>;
}
```

A static property wrapping the page's `<link rel="icon">` element. Reading it returns the element's current `href` attribute, or `null` if no such link element exists yet. Writing creates the link element (with `rel="icon"`) on first use if none exists yet, then sets/updates its `href`; writing `null` removes the `href` attribute from an existing link element (leaving the element itself in place), and is a no-op if no link element exists yet.

### ActivityTracker

```haxe
class ActivityTracker
{
    public static function activate():Void
    public static function getLastActivityTs():Int
}
```

Tracks the Unix timestamp (in seconds) of the user's last interaction with the page. `activate()` attaches document-level listeners for `mousedown`, `mousemove`, `keypress`, `scroll` and `touchstart`, each updating the tracked timestamp; call it once, typically at startup - calling it again attaches a second set of listeners rather than replacing the first, redundantly updating the same timestamp on every subsequent event instead of changing what gets tracked. `getLastActivityTs()` returns the tracked timestamp, or `0` if `activate()` was never called or no tracked event has fired yet.

### Clipboard

```haxe
class Clipboard
{
    public static function copy(text:String, ?onSuccess:Void->Void, ?onError:Void->Void):Void
}
```

Writes `text` to the system clipboard via the browser's asynchronous Clipboard API. `onSuccess` runs if the write succeeds, `onError` if it's rejected (e.g. the page lacks clipboard permission); both are optional, and `onError` isn't passed the underlying rejection reason.

## Reference

### CSS classes and elements

Ids marked `<...>` are per-instance (built from a slug/id supplied in config); class selectors are the more generally useful override point unless a specific instance needs to be targeted.

#### Page container

| Selector | Notes |
|---|---|
| `.haxefolio-page-container` / `#haxefolio-page-container` | The box the active page is mounted into. |

#### Menu bar and side bar

| Selector | Notes |
|---|---|
| `.haxefolio-menubar` | The `MenuBar` itself. Its own buttons/icons carry HaxeUI's built-in `menubar-button`/`menuitem-icon` classes - scope overrides with e.g. `.haxefolio-menubar > .menubar-button`. |
| `.haxefolio-hamburger-button` / `#haxefolio-hamburger-button-menubar`, `#haxefolio-hamburger-button-sidebar` | The hamburger button - one instance in the menu bar, one in the side bar. |
| `.haxefolio-site-name-label` / `#haxefolio-site-name-label-menubar`, `#haxefolio-site-name-label-sidebar` | The site name label - one instance in the menu bar, one in the side bar. |
| `.haxefolio-normal-menu` / `#haxefolio-normal-menu-<slug>` | A `NormalMenu`. |
| `.haxefolio-normal-menu-item` / `#haxefolio-normal-menu-<menuSlug>-item-<itemSlug>` | A menu item within a `NormalMenu`. |
| `.haxefolio-sidebar` | The `SideBar` itself. |
| `.haxefolio-sidebar-entries-top-spacer` | Spacer between the first row and the group list. |
| `.haxefolio-sidebar-group-header` / `#haxefolio-sidebar-group-header-<slug>` | A side bar group's header label - covers both menu-mirrored and `sidebarExtras` groups. |
| `.haxefolio-sidebar-group-item` / `#haxefolio-sidebar-group-item-<groupSlug>-<itemSlug>` | A side bar group's item label. |

#### Preference window

| Selector | Notes |
|---|---|
| `.haxefolio-preference-modal` / `#haxefolio-preference-modal` | Desktop presentation's modal box. |
| `.haxefolio-preference-backdrop` / `#haxefolio-preference-backdrop` | Desktop presentation's backdrop; also carries HaxeUI's own `modal-background` class. |
| `.haxefolio-preference-sidebar` / `#haxefolio-preference-sidebar` | Mobile presentation's `SideBar`. |
| `.haxefolio-preference-close-button` / `#haxefolio-preference-close-button` | The close button, shared shape in both presentations. |
| `.haxefolio-preference-content` / `#haxefolio-preference-content` | The shared content box (tabs + footer) both presentations wrap. |
| `#haxefolio-preference-tabview` | The `TabView`; icons within it (from `preferenceTabIcons`) default to 16x16 via `#haxefolio-preference-tabview .icon`. |
| `.haxefolio-preference-tab` / `#haxefolio-preference-tab-<tabId>` | A single tab page. |
| `.haxefolio-preference-row` / `#haxefolio-preference-row-<id>` | A preference's row (toggle or option alike). |
| `.haxefolio-preference-name-label` / `#haxefolio-preference-name-label-<id>` | A preference row's name label. |
| `.haxefolio-preference-option-row` / `#haxefolio-preference-option-row-<id>` | An option (or `locale`) preference's button row. |
| `.haxefolio-preference-option-button` / `#haxefolio-preference-option-button-<id>-<value>` | An option (or `locale`) preference's value button. |
| `.haxefolio-preference-toggle` / `#haxefolio-preference-switch-<id>` | A toggle preference's switch; also carries HaxeUI's own `pill-switch` class. |
| `.haxefolio-preference-footer` / `#haxefolio-preference-footer` | The footer row (reset button + autosave notice). |
| `.haxefolio-preference-reset-button` / `#haxefolio-preference-reset-button` | The reset button. |
| `.haxefolio-preference-autosave-notice` / `#haxefolio-preference-autosave-notice` | The autosave notice label. |

### Locale keys

Every piece of menu bar, side bar and preference window text - except the literal `siteName` - is resolved through HaxeUI's localization system under the keys below. A missing entry throws.

| Key | Purpose |
|---|---|
| `haxefolio.menubar.menu.<slug>` | A `NormalMenu`'s label - also used for its mirrored side bar group header, since every `NormalMenu` is mirrored there under the same key |
| `haxefolio.menubar.menu.<menuSlug>.item.<itemSlug>` | A menu item's label - shared with its side bar mirror the same way |
| `haxefolio.sidebar.extra_group.<slug>` | A `sidebarExtras` group's header label |
| `haxefolio.sidebar.extra_group.<slug>.item.<itemSlug>` | A `sidebarExtras` group item's label |
| `haxefolio.preference.tab.<tabId>` | A preference tab's label |
| `haxefolio.preference.<id>.name` | A preference's display name |
| `haxefolio.preference.<id>.value.<value>` | An option (or `locale`) preference's value button label |
| `haxefolio.preference.reset` | The preference window's reset button label |
| `haxefolio.preference.autosave_notice` | The preference window's autosave notice label |

`defaultTitleKey`, and the `key` argument to `setTitle`/`startBlink`, are ordinary locale keys of the app's own choosing (see `Page title and notifications`) - not a fixed convention, so they aren't listed above.
