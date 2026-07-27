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
private function setTitle(text:String, ?param0:Any, ?param1:Any, ?param2:Any, ?param3:Any):Void
private function startBlink(text:String, ?param0:Any, ?param1:Any, ?param2:Any, ?param3:Any, ?iconHref:String, intervalMs:Int = 1000):Void
private function stopBlink():Void
```

`setTitle` assigns `document.title` to `LocaleUtils.resolveText(text, param0, param1, param2, param3)` (see `LocaleUtils.resolveText` below) and is callable from `init` or any later point (e.g. once data that only becomes available asynchronously has arrived). If a page's `init` completes without ever calling `setTitle`, the framework falls back to `HaxeFolioConfig.defaultTitleText` (resolved with no params), if given, or else `siteName`.

`LocaleUtils.resolveText` is the one-shot counterpart to a HaxeUI `.text` property binding:

```haxe
class LocaleUtils
{
    public static function resolveText(text:String, ?param0:Any, ?param1:Any, ?param2:Any, ?param3:Any):String
}
```

`text` is interpreted the same way any HaxeUI `.text` property is: a literal by default, or - if `text` is exactly one `{{key}}` binding (the whole string, not a literal prefix/suffix mixed with a binding) - a locale key, in which case `param0`-`param3` are substituted for `[0]`-`[3]` in the resolved locale string, per HaxeUI's own `LocaleManager.lookupString` convention. A `text` that's a plain literal, or that mixes literal text with a binding, is returned as-is - `param0`-`param3` are ignored in both cases.

`startBlink` alternates the tab title between its current value and `LocaleUtils.resolveText(text, param0, param1, param2, param3)`, once every `intervalMs` (1000 by default). Passing `iconHref` swaps the favicon in lockstep - notification icon while showing the notification text, restored otherwise; omit it to blink only the title. It can only be called after `setTitle` (throws otherwise), and replaces any already-active blink for the page rather than stacking. `stopBlink` restores the pre-blink title/favicon; it's a no-op if nothing is blinking, and the framework also calls it automatically whenever a page is torn down, so forgetting to call it isn't a way to leak a blink into the next page:

```haxe
simulateChallengeButton.onClick = _ -> startBlink("{{page.home.notification.challenge}}", 1, null, null, null, NOTIFICATION_ICON);
```

If the app declares a language preference (see `Preferences`) and wires it into `HaxeFolioConfig.languagePreference`, a page's title/blink text stays in sync with it automatically, the same way `{{key}}`-bound component text elsewhere refreshes via HaxeUI's own locale-change mechanism - but only if that text is itself a `{{key}}` binding; a literal title/blink text has nothing to resync, so it's simply left as-is on a locale change. Apps that don't declare a language preference get no such refresh, since nothing else changes the active locale at runtime.

The blinking itself (the timer, the title/favicon swap) is implemented by `haxefolio.browser.Blinker`/`Favicon`, bundled utilities with no dependency on the rest of HaxeFolio, HaxeUI, or locale - usable directly in any HTML5 Haxe app that already has HaxeFolio as a dependency. `PageBase.startBlink`/`stopBlink` are a thin, localization-aware convenience layer on top of them. Deciding *when* to call them (e.g. reacting to `document.visibilitychange`/`document.hidden` to detect the user being away from the tab) is left entirely to the framework user's own code.

## Menu and side bar

The top of the app is a menu bar (`haxe.ui.containers.menus.MenuBar`); a side bar (`haxe.ui.containers.SideBar`, hidden until opened) mirrors it for narrow screens. Both are built from the same `HaxeFolioConfig.menubar`/`sidebarExtras` configuration.

### Menu bar

The menu bar can hold four kinds of items, assembled into `left`/`right` groups (`HaxeFolioConfig.menubar.left`/`.right`, each an `Array<MenuBarItem>` in layout order):

```haxe
enum MenuBarItem
{
    SiteName;
    NormalMenu(slug:String, items:Array<MenuItemDefinition>, ?defaultText:String);
    Widget(component:Component, ?persistent:Bool);
}
```

- **`SiteName`** - a label showing `HaxeFolioConfig.siteName`, interpreted the same way any HaxeUI `.text` property is (see `LocaleUtils.resolveText` in `Page title and notifications`); navigates to the default page when clicked.
- **`NormalMenu(slug, items, ?defaultText)`** - an ordinary dropdown menu, identified by `slug` (also used to build its CSS id, and - absent `defaultText` - its locale key, see `Locale keys` in `Reference`). `defaultText`, if given, is used verbatim as the menu's initial label, interpreted the same way any HaxeUI `.text` property is; omitted, the label defaults to the derived locale key. Each `MenuItemDefinition` is `{slug, action, ?icon, ?defaultText}` (`defaultText` working the same way, per item), where `action` is:

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

### Updating menu bar labels at runtime

`MenuFacade` (`haxefolio.menu.MenuFacade`) exposes:

```haxe
public static function updateSiteNameLabelText(text:String):Void
public static function updateMenuLabelText(slug:String, text:String):Void
public static function updateMenuItemLabelText(menuSlug:String, itemSlug:String, text:String):Void
```

`updateSiteNameLabelText` changes the `SiteName` label; `updateMenuLabelText` changes the label of the `NormalMenu` identified by `slug`; `updateMenuItemLabelText` changes the label of one of its items, identified by `menuSlug`/`itemSlug`. Each of these updates both the menu bar's own label and its mobile side bar mirror (see `Side bar` below) together, in one call, so the two can never go out of sync through this API. `updateMenuLabelText`/`updateMenuItemLabelText` throw if no such `NormalMenu`/item is present in the menu bar; `updateSiteNameLabelText` throws only if the menu bar has no `SiteName` item to update (the side bar's `SiteName` label always exists, so it's always updated). In every case, `text` is interpreted exactly like any other HaxeUI `.text` property: a literal label by default, or - enclosed in `{{}}`, e.g. `"{{haxefolio.menubar.menu.navigation}}"` - a locale key, re-resolved automatically on every locale change.

### Side bar

The side bar's first row always holds a hamburger button (closes the side bar) and the site name (closes the side bar and navigates to the default page). Below that, every `NormalMenu` from the menu bar is mirrored as a group: a header line with the menu's own label, followed by an indented, clickable line per item - clicking closes the side bar, then runs the same action as the menu bar counterpart.

The side bar's `SiteName` label and every mirrored group/item label are built from the very same `siteName`/`defaultText` (or derived locale key) as their menu bar counterparts, and stay coherent with them afterwards too: any `MenuFacade` update (see `Updating menu bar labels at runtime` above) applies to both the menu bar's label and its side bar mirror together.

`HaxeFolioConfig.sidebarExtras` adds further, side-bar-only groups in the same shape:

```haxe
typedef SidebarGroup = {
    slug:String,
    items:Array<MenuItemDefinition>
}
```

Their main use is replicating navigational aspects of non-persistent menu bar `Widget`s - e.g. an "Account" group with "Log in"/"Sign up" entries, standing in for a widget that's hidden once the menu bar collapses.

Absent an explicit `defaultText`, every menu/item/group label goes through localization; see `Locale keys` in `Reference` for the exact key convention.

## Responsivity

HaxeFolio reacts to viewport size changes - window resizing on desktop, orientation changes on mobile - resizing the menu bar and notifying the active page, debounced (`HaxeFolioConfig.debounceMs`; defaults to 500) so a drag-resize doesn't trigger continuous work.

Below `HaxeFolioConfig.menuCollapseWidth` (an author-chosen width past which the menu bar no longer fits everything; defaults to 900), the menu bar hides its `NormalMenu`s and any `Widget` not marked `persistent`, and reveals the hamburger button to reach the side bar instead. Above it, the reverse. Deciding *what* happens at the threshold is HaxeFolio's job; the framework user only supplies the threshold itself and which widgets should stay persistent.

Independently of that threshold, every time the page container is resized, the active page's `onResize(width, height)` is called with its new pixel dimensions (see `Pages`) - overriding it to react to size changes is the framework user's responsibility.

## Overlays

HaxeFolio includes a generic, dismissible-overlay mechanism - the same responsive modal/sidebar
presentation the preference window uses (see `Preference window` below), available for a framework
user's own arbitrary HaxeUI content too. Which presentation appears is picked the same way
responsivity elsewhere is - a bottom `SideBar` covering the entire viewport while the menu bar is
collapsed (mobile), a centered modal over the page container otherwise (desktop), based on
`menuCollapseWidth`.

The two presentations deliberately differ in how much of the app they block, and this isn't
incidental:

- The **desktop modal is non-blocking** - the rest of the app, menu bar included, stays fully
  interactive while it's open; the modal only ever captures clicks landing on its own box.
  Closeable via its close button, a `dismiss()` call from its own content, or by navigating away
  (which force-closes it rather than leaving it stranded over an unrelated page) - there is no
  click-outside-to-dismiss.
- The **mobile sidebar is fully exclusive** - the entire rest of the app is inert for as long as
  it's open, opening, or closing, with no gap even mid-slide-animation; nothing beneath it is
  reachable until it's completely gone.

### Overlay content

`OverlayContent` is a plain `VBox` a framework user instantiates directly and populates:

```haxe
var content:OverlayContent = new OverlayContent();
content.addComponent(new Label("Hello!"));
```

`addDetachable(detachable:Detachable):Void` registers a `Detachable` (e.g. a `Preference.onChange`
handle) to be detached automatically once the overlay is dismissed - the same contract
`PreferenceWindowBuilder` relies on for the preference window's own rows.

### Showing an overlay

```haxe
HaxeFolioApp.showOverlay(slug:String, contentFactory:(Void->Void)->OverlayContent, ?width:Int, ?height:Int, ?closeButtonSize:Int, ?closeButtonInsetX:Int, ?closeButtonInsetY:Int, showCloseButton:Bool = true, ?mobileContentFactory:(Void->Void)->OverlayContent, ?onDismissed:Void->Void):Void
```

- `slug` identifies the overlay for CSS purposes (see `Overlay styling` below) - must be unique
  across every `showOverlay` call site in the app, including the built-in preference window's own
  `"preference"`.
- `contentFactory` is only invoked if the call isn't a no-op (see below), and receives a `dismiss`
  callback the built content can call to close the overlay itself - e.g. wiring it into a "Save &
  Close" button:

  ```haxe
  HaxeFolioApp.showOverlay("my-overlay", dismiss ->
  {
      var content:OverlayContent = new OverlayContent();
      var saveButton:Button = new Button();
      saveButton.text = "Save & Close";
      saveButton.onClick = _ -> dismiss();
      content.addComponent(saveButton);
      return content;
  });
  ```
- `width`/`height` apply to the modal presentation only, ignored for the mobile sidebar which is
  always full-viewport; both default to CSS (see `Overlay styling`) when omitted.
- `closeButtonSize`/`closeButtonInsetX`/`closeButtonInsetY` likewise default to CSS/the overlay's
  own live padding rather than a hardcoded value when omitted.
- `showCloseButton: false` omits the close button entirely - the content's own `dismiss` callback
  (above) becomes the only way to close such an overlay, so a custom close affordance is the
  caller's responsibility in that case.
- `mobileContentFactory`, optional - when given, used instead of `contentFactory` for the mobile
  sidebar presentation, letting a framework user supply genuinely different component trees for the
  two presentations; omitted, `contentFactory` is reused for both (the common case, and what the
  preference window itself does).

Only one overlay - built-in or custom - may be open at a time: calling `showOverlay` again while
one is already open (or mid-close) is a no-op, and any navigation away while an overlay is open
closes it first (see `Navigation`).

### Overlay styling

Every default this section covers - size, close button icon, close button size - is overridable
purely via CSS, following the same class-vs-id cascade as the rest of HaxeFolio's chrome (see
`Styling`): target the generic class for a blanket change across every overlay, or
`#haxefolio-overlay-<slug>-*` for a single one. For example, to use a different close icon just for
one overlay:

```css
#haxefolio-overlay-my-overlay-close-button {
    resource: 'assets/my-close-icon.svg';
}
```

See `Overlays` in `CSS classes and elements` for the full selector list and their defaults.

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

The same namespaced LocalStorage access preferences are built on is also exposed directly, for a framework user's own arbitrary key-value data, via `HaxeFolioApp.valueStorage`:

```haxe
class StorageBackend
{
    public function has(id:String):Bool
    public function read(id:String):Null<String>
    public function write(id:String, value:String):Void
}
```

`has`/`read`/`write` all key into the same `<hostname>.<appSlug>.<id>` namespace described above - `id` should therefore be chosen to avoid colliding with any declared preference's own `id`, since a colliding pair reads/writes the very same LocalStorage entry. As with preference values, `valueStorage` isn't available before `HaxeFolioApp.init` has run.

### Preference window

The preference window's content - tabs and controls - is generated at runtime from what `Preferences` declared, organized as one `TabView` tab per `tabId`, each optionally iconed via `HaxeFolioConfig.preferenceTabIcons` (mapping `tabId` to an icon asset path). Each tab contains a control per preference assigned to it, in declaration order: a slider for `toggle`, a row of buttons (one per admissible value, current one marked active) for `option`/`locale`. Below the tabs, a footer holds a reset button (`PreferenceRegistry.resetAll()`) and a label noting that changes save automatically - there's no separate "OK"/"Apply" step.

A framework user opens the window by calling `HaxeFolioApp.showPreferences()` - typically from a menu bar `Widget`'s `onClick`, or an `Execute` menu action (as in `Getting started` above). This is built directly on the generic `showOverlay` mechanism described in `Overlays` above, with slug `"preference"`, and inherits its presentation/dismissal/no-op rules from there rather than having its own; its desktop modal size (480x360) comes from the `#haxefolio-overlay-preference-modal` CSS default (see `Overlay styling`), not a hardcoded value.

Every displayed string is localized; see `Locale keys` in `Reference`.

## Configuration

`HaxeFolioApp.init(config:HaxeFolioConfig)` wires up everything described above. `config` can be built either as a plain anonymous structure, or via the fluent `HaxeFolioConfigBuilder` shown in `Getting started` - both produce the same `HaxeFolioConfig`.

### HaxeFolioConfig

| Field | Type | Notes |
|---|---|---|
| `appSlug` | `String` | App identifier; namespaces LocalStorage entries (see `Preference storage`) and distinguishes this site from other HaxeFolio-based sites. |
| `appIcon` | `String` | Icon path for the `HaxeUIApp`/browser tab. |
| `siteName` | `String` | `SiteName` menu bar item text - see `Menu bar` for how it's interpreted. |
| `?menuCollapseWidth` | `Int` | Mobile/desktop breakpoint (see `Responsivity`). Defaults to 900. |
| `?debounceMs` | `Int` | Resize handling debounce interval, in milliseconds (see `Responsivity`). Defaults to 500. |
| `pages` | `Array<PageDefinition>` | See `Registering pages`. |
| `menubar` | `MenuBarConfig` (`{left, right}`) | See `Menu bar`. |
| `?sidebarExtras` | `Array<SidebarGroup>` | See `Side bar`. |
| `?defaultTitleText` | `String` | Fallback tab title text (see `Page title and notifications` for how it's interpreted) for pages that never call `setTitle`; falls back further to `siteName` if omitted too. |
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

`MenuFacade.menuBar`/`sideBar` are also exposed as static members, letting a framework user reach into either component and adjust properties directly - once, right after `HaxeFolioApp.init` returns (there's no need to account for redraws, since this only runs once at startup). No overlay - the built-in preference window included - has an equivalent static member: unlike the menu bar/side bar, an overlay isn't built once at startup - a fresh instance is built on every `showOverlay`/`showPreferences()` call instead, since it must pick one of its two presentations depending on the current layout mode (see `Overlays`). The preference window's supported customization points are instead `HaxeFolioConfig.preferenceTabIcons` and CSS.

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

Tracks the Unix timestamp (in seconds) of the user's last interaction with the page. `activate()` attaches document-level listeners for `mousedown`, `mousemove`, `keypress`, `scroll` and `touchstart`, each updating the tracked timestamp; call it once, typically at startup - calling it again has no effect. `getLastActivityTs()` returns the tracked timestamp, or `0` if `activate()` was never called or no tracked event has fired yet.

### Clipboard

```haxe
class Clipboard
{
    public static function copy(text:String, ?onSuccess:Void->Void, ?onError:Dynamic->Void):Void
}
```

Writes `text` to the system clipboard via the browser's asynchronous Clipboard API. `onSuccess` runs if the write succeeds, `onError` if it's rejected (e.g. the page lacks clipboard permission); both are optional, and `onError` is passed the underlying rejection reason.

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

#### Overlays

| Selector | Notes |
|---|---|
| `.haxefolio-overlay-modal` / `#haxefolio-overlay-<slug>-modal` | Desktop presentation's modal box. Deliberately non-blocking - captures clicks landing on itself only, never the rest of the app (see `Overlays` above). No default `width`/`height` (auto-sized to content) unless a specific overlay's id sets one or `showOverlay` is given an explicit value - see `#haxefolio-overlay-preference-modal` below for the built-in example. |
| `.haxefolio-overlay-backdrop` / `#haxefolio-overlay-<slug>-backdrop` | Mobile sidebar presentation only - a full-screen input blocker present for the entire time the sidebar is open, opening, or closing (see `Overlays` above), with no click-to-dismiss. The desktop modal has no backdrop at all. |
| `.haxefolio-overlay-sidebar` / `#haxefolio-overlay-<slug>-sidebar` | Mobile presentation's `SideBar`. |
| `.haxefolio-overlay-close-button` / `#haxefolio-overlay-<slug>-close-button` | The close button, shared shape in both presentations. Defaults to `14px`/`14px` and the framework's own close icon (via CSS `resource`) - override either per-overlay via the id, or globally via the class. Omitted entirely (not just hidden) for an overlay shown with `showCloseButton: false`. |
| `.haxefolio-overlay-content` / `#haxefolio-overlay-<slug>-content` | The `OverlayContent` itself, both presentations wrap. |

#### Preference window

The preference window is itself an overlay, slug `"preference"` - see `Overlays` above for its
modal/backdrop/sidebar/close-button/content chrome selectors. Its own selector is just its default
desktop modal size:

| Selector | Notes |
|---|---|
| `#haxefolio-overlay-preference-modal` | `width: 480px; height: 360px;` - the preference window's own default modal size (see `Overlay styling`). |
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

Every piece of preference window text, and every menu bar/side bar label not given an explicit `defaultText` (see `Menu bar`), is resolved through HaxeUI's localization system under the keys below.

A locale entry that's missing entirely does **not** throw - HaxeUI's `LocaleManager` falls back to displaying the raw key itself (e.g. a literal `haxefolio.menubar.menu.navigation` on screen) wherever that key was bound. There is no HaxeFolio-level validation catching this earlier; a missing entry is a visible-at-runtime, not a thrown, failure.

| Key | Purpose |
|---|---|
| `haxefolio.menubar.menu.<slug>` | A `NormalMenu`'s label, absent `defaultText` - also used for its mirrored side bar group header the same way, absent the `NormalMenu`'s `defaultText` |
| `haxefolio.menubar.menu.<menuSlug>.item.<itemSlug>` | A menu item's label, absent `defaultText` - shared with its side bar mirror the same way |
| `haxefolio.sidebar.extra_group.<slug>` | A `sidebarExtras` group's header label |
| `haxefolio.sidebar.extra_group.<slug>.item.<itemSlug>` | A `sidebarExtras` group item's label, absent `defaultText` |
| `haxefolio.preference.tab.<tabId>` | A preference tab's label |
| `haxefolio.preference.<id>.name` | A preference's display name |
| `haxefolio.preference.<id>.value.<value>` | An option (or `locale`) preference's value button label |
| `haxefolio.preference.reset` | The preference window's reset button label |
| `haxefolio.preference.autosave_notice` | The preference window's autosave notice label |

`siteName`, `defaultTitleText`, and the `text` argument to `setTitle`/`startBlink`/`MenuFacade`'s update methods, are ordinary HaxeUI strings (see `Menu bar` and `Page title and notifications`) - `{{key}}`-wrapped locale keys are the app's own choosing there, not a fixed convention, so they aren't listed above.
