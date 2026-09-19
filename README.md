# HaxeFolio Manual

HaxeFolio is a framework for building a HaxeUI HTML5 single-page web app. It lays out a menu bar and a page container, and the app is composed of "pages" swapped in and out of that container as the URL changes - from a general web technology perspective the site is still a single HTML page, so HaxeFolio's own notion of "page" (a HaxeUI component, not a document) is worth keeping in mind throughout this manual. HaxeFolio is built over the HaxeUI library and targets HTML5.

## Getting started

At minimum, an app registers its pages and menu, and calls `HaxeFolioApp.init`. For example:

```haxe
class Main
{
    public static function main():Void
    {
        var config:HaxeFolioConfig = HaxeFolioConfigBuilder.init("my-app", Preferences)
            .setAppIcon("assets/favicons/normal.png")
            .setSiteName("My App")
            .addPage("home", params -> new HomePage(), true)
            .addPage("user/{login}", params -> new UserPage(params["login"]))
            .addLeftMenubarItem(NormalMenu("navigation", []))
            .addNormalMenuItem("navigation", "home", NavigateTo(() -> "home"))
            .addRightMenubarItem(Widget(buildSettingsWidget, true))
            .setLanguagePreference(Preferences.language)
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

`setTitle` assigns `document.title` to `LocaleUtils.resolveText(text, param0, param1, param2, param3)` and is callable from `init` or any later point (e.g. once data that only becomes available asynchronously has arrived). If a page's `init` completes without ever calling `setTitle`, the framework falls back to `HaxeFolioConfig.defaultTitleText` (resolved with no params), if given, or else `siteName`. `text`/`param0`-`param3` are interpreted the same way any HaxeUI `.text` property is - see `Locale utilities` below for exactly how, and for the rest of what `LocaleUtils` offers directly to a framework user's own code.

`startBlink` alternates the tab title between its current value and `LocaleUtils.resolveText(text, param0, param1, param2, param3)`, once every `intervalMs` (1000 by default). Passing `iconHref` swaps the favicon in lockstep - notification icon while showing the notification text, restored otherwise; omit it to blink only the title. It can only be called after `setTitle` (throws otherwise), and replaces any already-active blink for the page rather than stacking. `stopBlink` restores the pre-blink title/favicon; it's a no-op if nothing is blinking, and the framework also calls it automatically whenever a page is torn down, so forgetting to call it isn't a way to leak a blink into the next page:

```haxe
simulateChallengeButton.onClick = _ -> startBlink("{{page.home.notification.challenge}}", 1, null, null, null, NOTIFICATION_ICON);
```

If the app declares a language preference (see `Preferences`) and wires it into `HaxeFolioConfig.languagePreference`, a page's title/blink text stays in sync with it automatically, the same way `{{key}}`-bound component text elsewhere refreshes via HaxeUI's own locale-change mechanism - but only if that text is itself a `{{key}}` binding; a literal title/blink text has nothing to resync, so it's simply left as-is on a locale change. Apps that don't declare a language preference get no such refresh, since nothing else changes the active locale at runtime.

The blinking itself (the timer, the title/favicon swap) is implemented by `haxefolio.browser.Blinker`/`Favicon`, bundled utilities with no dependency on the rest of HaxeFolio, HaxeUI, or locale - usable directly in any HTML5 Haxe app that already has HaxeFolio as a dependency. `PageBase.startBlink`/`stopBlink` are a thin, localization-aware convenience layer on top of them. Deciding *when* to call them (e.g. reacting to `document.visibilitychange`/`document.hidden` to detect the user being away from the tab) is left entirely to the framework user's own code.

## Locale utilities

`LocaleUtils` (`haxefolio.LocaleUtils`) is the framework's own convention for interpreting a string as either a literal or a `{{key}}`-bound locale key - the same interpretation every HaxeUI `.text` property already gives such a string when it's live-bound to a component, but available here as a plain, one-shot function of `String`s. It's what `PageBase.setTitle`/`startBlink` (see `Page title and notifications` above), `MenuFacade`'s label-updating methods (see `Updating menu bar labels at runtime` below), and the preference window are themselves built on - and, having no dependency on any particular page/menu/preference state, it's equally available for a framework user's own code wherever the same literal-or-locale-key convention is wanted, e.g. resolving a locale-aware label for a component built and populated by hand rather than through HaxeUI's own `.text` binding:

```haxe
class LocaleUtils
{
    public static function resolveText(text:String, ?param0:Any, ?param1:Any, ?param2:Any, ?param3:Any):String
    public static function extractLocaleKey(text:String):Null<String>
    public static function localeBinding(key:String, ?paramExpr0:String, ?paramExpr1:String, ?paramExpr2:String, ?paramExpr3:String):String
}
```

- `resolveText` is the one-shot counterpart to a HaxeUI `.text` property binding: `text` is interpreted the same way any HaxeUI `.text` property is - a literal by default, or - if `text` is exactly one `{{key}}` binding (the whole string, not a literal prefix/suffix mixed with a binding) - a locale key, in which case `param0`-`param3` are substituted for `[0]`-`[3]` in the resolved locale string, per HaxeUI's own `LocaleManager.lookupString` convention. A `text` that's a plain literal, or that mixes literal text with a binding, is returned as-is - `param0`-`param3` are ignored in both cases. Unlike a live `.text` binding, the result is computed once at the call site and doesn't refresh itself on a later locale change - a caller that needs to stay in sync (as `setTitle`/`startBlink` and `MenuFacade` do) is responsible for re-resolving on its own, typically from a language preference's `onChange` handler (see `Reacting to changes`).
- `extractLocaleKey` is what `resolveText` uses to tell the two cases apart, and is available on its own for code that needs to make that same distinction without also resolving the string: given `text` shaped as exactly one whole-string `{{key}}` binding, it returns `key`; given anything else (`null`, a plain literal, or a binding mixed with other text), it returns `null`.
- `localeBinding` is the inverse of `extractLocaleKey` - it builds the `{{key}}` string (or `{{key, paramExpr0, paramExpr1, ...}}`, stopping at the first omitted `paramExpr`) from `key` and however many of `paramExpr0`-`paramExpr3` are given, for code that needs to construct such a binding rather than write it as a string literal, e.g. assembling a `.text` value from a locale key computed at runtime. `paramExpr0`-`paramExpr3` here are Haxe expression source embedded verbatim into the binding (e.g. `"someVar"` or `"1"`), the same way HaxeUI's own `{{key, someExpression}}` markup takes expressions - not values, unlike `resolveText`'s `param0`-`param3` above.

## Menu and side bar

The top of the app is a menu bar (`haxe.ui.containers.menus.MenuBar`); a side bar (`haxe.ui.containers.SideBar`, hidden until opened) mirrors it for narrow screens. Both are built from the same `HaxeFolioConfig.menubar`/`sidebarExtras` configuration.

### Menu bar

The menu bar can hold two kinds of user-defined items, assembled into `left`/`right` groups (`HaxeFolioConfig.menubar.left`/`.right`, each an `Array<MenuBarItem>` in layout order):

```haxe
enum MenuBarItem
{
    NormalMenu(slug:String, items:Array<MenuItemDefinition>, ?defaultText:String);
    Widget(componentFactory:Void->Component, ?persistent:Bool);
}
```

- **`NormalMenu(slug, items, ?defaultText)`** - an ordinary dropdown menu, identified by `slug` (also used to build its CSS id, and - absent `defaultText` - its locale key, see `Locale keys` in `Reference`). `defaultText`, if given, is used verbatim as the menu's initial label, interpreted the same way any HaxeUI `.text` property is; omitted, the label defaults to the derived locale key. Each `MenuItemDefinition` is `{slug, action, ?icon, ?defaultText, ?hiddenByDefault}` (`defaultText` working the same way, per item), where `action` is:

  ```haxe
  enum MenuAction
  {
      NavigateTo(pathFactory:Void->String);
      Execute(fn:Void->Void);
      Link(url:String, newTab:Bool);
  }
  ```

  `NavigateTo` goes through `HaxeFolioApp.navigateTo` just like any other navigation; `Execute` runs an arbitrary function, which may itself call `navigateTo` if it needs to combine navigation with something `NavigateTo` alone doesn't cover (e.g. passing `state`). `Link` opens `url` in a new tab if `newTab` is `true`, or the current one otherwise - a shorthand for an `Execute` whose callback opens `url` via `window.open` with the respective target.
- **`Widget(componentFactory, ?persistent)`** - a custom component, built by `componentFactory` and wrapped in its own menu, e.g. the settings button shown in `Getting started`. The factory is only invoked once the menu bar itself is being built (i.e. after `Toolkit.init()` has run as part of `HaxeFolioApp.init`), since HaxeUI components can't be constructed any earlier.

`hiddenByDefault`, if `true`, starts a `MenuItemDefinition` hidden - in the menu bar and, for a `NormalMenu` item, its mirrored side bar entry too - until `MenuFacade.showMenuItem`/`showSidebarExtraGroupItem` (see `Showing and hiding menu items at runtime` below) makes it visible; omitted, it defaults to `false`.

Additionally, two components are always present as the menu bar's leftmost children, placed there by the framework itself rather than configured as `MenuBarItem`s: a hamburger button - hidden by default, shown once the menu bar collapses to its mobile layout (see `Responsivity`), at which point clicking it opens the side bar - followed by the site name label, showing `HaxeFolioConfig.siteName` (interpreted the same way any HaxeUI `.text` property is, see `Locale utilities`) and navigating to the default page when clicked.

### Updating menu bar labels at runtime

`MenuFacade` (`haxefolio.menu.MenuFacade`) exposes:

```haxe
public static function updateSiteNameLabelText(text:String):Void
public static function updateMenuLabelText(slug:String, text:String):Void
public static function updateMenuItemLabelText(menuSlug:String, itemSlug:String, text:String):Void
```

`updateSiteNameLabelText` changes the site name label; `updateMenuLabelText` changes the label of the `NormalMenu` identified by `slug`; `updateMenuItemLabelText` changes the label of one of its items, identified by `menuSlug`/`itemSlug`. Each of these updates both the menu bar's own label and its mobile side bar mirror (see `Side bar` below) together, in one call, so the two can never go out of sync through this API. `updateMenuLabelText`/`updateMenuItemLabelText` throw if no such `NormalMenu`/item is present in the menu bar; `updateSiteNameLabelText` never throws, since both the menu bar and the side bar always have a site name label. In every case, `text` is interpreted exactly like any other HaxeUI `.text` property: a literal label by default, or - enclosed in `{{}}`, e.g. `"{{haxefolio.menubar.menu.navigation}}"` - a locale key, re-resolved automatically on every locale change.

### Updating menu bar item icons at runtime

`MenuFacade` also exposes:

```haxe
public static function updateMenuItemIcon(menuSlug:String, itemSlug:String, icon:String):Void
```

Updates the icon of the item identified by `itemSlug` within the `NormalMenu` identified by `menuSlug`. Unlike the label-updating methods above, this only touches the menu bar - the side bar has no icons of its own to keep in sync (see `Side bar` below). Throws if no such item is present in the menu bar.

### Showing and hiding menu items at runtime

`MenuFacade` also exposes:

```haxe
public static function showMenuItem(menuSlug:String, itemSlug:String):Void
public static function hideMenuItem(menuSlug:String, itemSlug:String):Void
public static function setMenuItemHidden(menuSlug:String, itemSlug:String, hidden:Bool):Void
public static function showSidebarExtraGroupItem(groupSlug:String, itemSlug:String):Void
public static function hideSidebarExtraGroupItem(groupSlug:String, itemSlug:String):Void
```

`showMenuItem`/`hideMenuItem`/`setMenuItemHidden` show/hide the item identified by `itemSlug` within the `NormalMenu` identified by `menuSlug`, together with its mirrored side bar item, the same way `hiddenByDefault` above starts it hidden. `showSidebarExtraGroupItem`/`hideSidebarExtraGroupItem` do the same for an item within a `sidebarExtras` group (see `Side bar` below), which has no menu bar counterpart to keep in sync. All four throw if no such item is present in the menu bar/side bar, respectively.

### Side bar

The side bar's first row always holds a hamburger button (closes the side bar) and the site name (closes the side bar and navigates to the default page). Below that, every `NormalMenu` from the menu bar is mirrored as a group: a header line with the menu's own label, followed by an indented, clickable line per item - clicking closes the side bar, then runs the same action as the menu bar counterpart.

The side bar's site name label and every mirrored group/item label are built from the very same `siteName`/`defaultText` (or derived locale key) as their menu bar counterparts, and stay coherent with them afterwards too: any `MenuFacade` update (see `Updating menu bar labels at runtime` above) applies to both the menu bar's label and its side bar mirror together.

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

### Reacting to the collapse threshold directly

Beyond the menu bar itself, any component whose own layout should change at the same threshold - e.g. a row of controls that stacks vertically once space is tight - can read it directly, rather than inventing a second, competing breakpoint:

```haxe
class ResponsivityController
{
    public static var isCollapsed(default, null):Bool;
    public static function onCollapseChange(listener:Bool->Void):Detachable
}
```

`isCollapsed` is the current state, kept live by the same resize handling described above. `onCollapseChange` registers `listener` to run whenever it actually flips (not on every debounced resize) - calling `listener` immediately, once, with the current value first, so a component built after the initial layout still starts in sync. Detach the returned handle once the component is done with it (e.g. a page's `onClose`), the same `Detachable` convention preferences use (see `Reacting to changes`).

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

## Form components

`haxefolio.form` is a small, general-purpose library of form/data-entry components. None of
them assume anything about their host - a page, a panel, a sidebar, or a `showOverlay` body
(see `Overlays`) are all equally valid; a host only needs to give one a width to size its
children's percentages against.

The package splits into two layers, the same split `haxefolio.menu`/`.builder` and
`haxefolio.preferences`/`.builder` already use elsewhere in the framework:

- **`haxefolio.form`** - the components a framework user actually reaches for and composes a
  form from: `ChoiceRow`, `ChoiceGrid`, `ToggleButton`, `FieldGroup`, `SwapSlot`, `SteppedValueField` (with `IntField`/`DurationField`), `CommitTextField`, `PreviewPane` below, and more as the library grows.
- **`haxefolio.form.plumbing`** - the primitives those components are built from
  (`FieldHeader`, `HintLine`, `ChoiceButton`, `Stepper`) and the shared model types (`HintState`,
  `EmphasisStyle`, `IconAlign`, `ChoiceOption<T>`, `ChoiceGridSelection<T>`, `ChoicesPerRow`, `FieldGroupDirection`, `CommitResult`, `CommitTrigger`, ...). Still public,
  and still useful directly for a bespoke field the higher-level components don't cover - just
  not the first thing to reach for.

### FieldHeader (`haxefolio.form.plumbing`)

A label on the left, an optional hint on the right, on one baseline-aligned row - the
building block for naming a control and, on the same line, stating its constraint or current
status:

```haxe
var header:FieldHeader = new FieldHeader("Initial time", "max 6:00:00");
header.state = Error;     // colours the hint `danger`; `Normal`/`Muted` both read as `inkMuted`
header.locked = true;     // greys the label only, independent of `state`
```

```haxe
public function new(label:String, ?hint:String, state:HintState = Normal, locked:Bool = false)
public var label(default, set):String;
public var hint(default, set):Null<String>;
public var state(default, set):HintState;
public var locked(default, set):Bool;
```

`HintState` is `Normal`/`Muted`/`Error` - only `Error` changes the hint's colour (to `danger`);
`Normal`/`Muted` both render `inkMuted`.

### HintLine (`haxefolio.form.plumbing`)

A fixed-height (16px) line of message text that's always present, whether or not `text` is
empty - what keeps a validation message appearing/disappearing from moving anything below it:

```haxe
var hint:HintLine = new HintLine("Must be above 0.", Error);
hint.text = "";   // still occupies its 16px line, just blank
```

```haxe
public function new(text:String = "", state:HintState = Normal)
public var state(default, set):HintState;
```

`text` is a plain HaxeUI `.text` property (inherited from `Label`), interpreted the same way
any other one is (see `Locale utilities`).

### ChoiceButton (`haxefolio.form.plumbing`)

One selectable button - the atom of a row/grid of options. Built on HaxeUI's own toggle
`Button` (`toggle = true`) rather than from scratch: `selected` is the toggled state, and
`componentGroup` (inherited from `Button`) is what keeps only one button selected within a
group - set the same `componentGroup` string on every button that should be mutually exclusive
(see `ChoiceRow` below for the common case):

```haxe
public function new(label:String, onClick:Void->Void, ?icon:String, iconAlign:IconAlign = Leading, selected:Bool = false, enabled:Bool = true)
```

Its selected-state styling hooks off `:down` - the pseudo-class a toggle `Button` already
applies for as long as `selected == true`, not just while the mouse is held - rather than a
class this component would otherwise have to manage itself. Which visual treatment `:down`
resolves to (`Filled`/`Outlined`) is not a constructor argument at all: it comes from the
enclosing host via the `haxefolio-emphasis-outlined` class (absent it, `Filled` - a solid
`accent` fill - is the default) on any ancestor, so every `ChoiceButton`/`ToggleButton` inside
a host agrees on what "active" looks like. `IconAlign` is `Leading`/`Trailing`.

A disabled button that is also selected (a locked row showing the value actually in effect) has
its own muted grey-blue look, `:down:disabled`: unmistakably "chosen", yet clearly inert, and
the same under both emphasis styles. This is the one place the stylesheet uses a chained
pseudo-class selector, which stock `haxeui-core` mis-parses (it drops all but the first
pseudo-class, so the rule would mute *every* selected button) - it needs the fix in
https://github.com/haxeui/haxeui-core/pull/713 (in the `Gulvan0/haxeui-core` fork's
`fix/compound-pseudo-class-selector` branch).

### Stepper (`haxefolio.form.plumbing`)

The `−` / value / `+` triple, with no header and no hint and no value semantics of its own -
the owning field (see `SteppedValueField`) parses, validates and applies steps. The buttons are
fixed width and the input flexes (`percentWidth = 100`), never the other way round:

```haxe
public function new(displayedText:String, onText:String->Void, onStep:Int->Void, enabled:Bool = true, invalid:Bool = false, buttonWidth:Int = 26)
public var displayedText(default, set):String;
public var invalid(default, set):Bool;    // red input border
public var enabled(default, set):Bool;    // disables both buttons and the input
```

`onText` fires only for genuine user edits, never as an echo of assigning `displayedText`;
`onStep` receives `-1`/`+1`. The name is `displayedText`, not `text`, because HaxeUI's `Component`
already owns `text`, `value` and `onChange` - a subclass can't redeclare them.

### ChoiceRow

An enumerable parameter as a row of equal-width `ChoiceButton`s under a `FieldHeader`.
Single-select: every button shares one generated `componentGroup`, so HaxeUI's own toggle
mechanism keeps exactly one selected - this component does no selection bookkeeping of its own:

```haxe
var row:ChoiceRow<String> = new ChoiceRow("Rated", [
    { value: "rated", label: "Rated" },
    { value: "unrated", label: "Unrated" }
], "rated", value -> trace('selected: $value'));
```

```haxe
public function new(label:String, options:Array<ChoiceOption<T>>, selected:T, onSelect:T->Void, stackOnCollapse:Bool = false, locked:Bool = false, ?lockReason:String)
public function dispose():Void
```

`ChoiceOption<T>` (`haxefolio.form.plumbing`) is `{value:T, label:String, ?icon:String}`.
`stackOnCollapse`, if `true`, switches the row from horizontal to a full-width vertical stack
whenever `ResponsivityController.isCollapsed` flips (see `Reacting to the collapse threshold
directly`) - call `dispose()` once the row is done with (e.g. a page's `onClose`) to detach that
listener; omit `stackOnCollapse` and there's nothing to detach. `locked`/`lockReason` disable
every button in place - never hiding the row - and state the reason via the header's own hint,
the same convention `FieldHeader.locked` already follows on its own.

### SwapSlot<K\>

A fixed-height region that shows one of several variants - built on HaxeUI's own `Stack`
rather than from scratch: `Stack` already shows exactly one child at a time and, given an
explicit height, already won't resize when the selection changes, since a hidden child is
excluded from layout. What this adds over a bare `Stack`: selecting by an arbitrary key `K`
(an enum, typically) instead of `Stack`'s own string id/int index, and a *required* `height`
argument, so "constant height, never measured" is part of the type rather than a convention a
bare `Stack` would let a caller forget:

```haxe
var slot:SwapSlot<ChallengeType> = new SwapSlot([
    Direct => directTypeContent,
    Open => openTypeContent
], Direct, 76);

slot.active = Open; // swaps content; height stays 76px
```

```haxe
public function new(variants:Map<K, Component>, active:K, height:Int)
public var active(default, set):K;
```

Setting `active` to a key that was never registered in `variants` throws - a mismatch there is
a programming error, not a case to accommodate. If a variant's content doesn't fit `height`,
fix the variant or the height; `SwapSlot` will not measure and resize around it - it also does
not clip on its own, so its `.haxefolio-swap-slot` class carries `clip: true;` (HaxeUI's
equivalent of CSS `overflow: hidden`); a variant taller than `height` is cut off cleanly rather
than bleeding into whatever the slot's host renders next.

### ChoiceGrid

The same selection semantics as `ChoiceRow`, but wrapping, for 6-20 curated options: rows of
`perRow.expanded` cells, or `perRow.collapsed` while `ResponsivityController.isCollapsed` (the
framework's one app-wide breakpoint - no component-local pixel threshold). Cell width is a
percentage of the row, and a short final row is padded with empty placeholders so its cells match
the full rows' width exactly. Whether it selects one option or several is chosen per instance by
a `ChoiceGridSelection<T>`:

```haxe
var grid:ChoiceGrid<Int> = new ChoiceGrid("Bonus preset", options, Single(currentBonus, value -> bonusField.currentValue = value), {expanded: 5, collapsed: 3});
var multi:ChoiceGrid<String> = new ChoiceGrid("Time controls", stringOptions, Multi(["Blitz"], (value, nowSelected) -> trace('$value: $nowSelected')), {expanded: 4, collapsed: 2});
```

```haxe
public function new(label:String, options:Array<ChoiceOption<T>>, selection:ChoiceGridSelection<T>, perRow:ChoicesPerRow, gap:Int = 6, locked:Bool = false, ?lockReason:String)
public function selectSingle(value:Null<T>):Void
public function selectMulti(values:Array<T>):Void
public function dispose():Void
```

`Single`'s `selected` is nullable, and that is the point: a grid of presets is a shortcut *into* a
value, not the value itself. The grid highlights what `selectSingle` last set, not merely which
cell was clicked, so a host that also has a "custom" editor for the same value (an `IntField`, say)
calls `selectSingle(value)` from that editor's `onChange` - a value no preset matches clears the
highlight, and a click on a preset fills the editor: one value, two editors, no sync state. (A
click still highlights its own cell at once, so the grid also works unbound.) `selectSingle` and
`selectMulti` do not call `onSelect`/`onToggle`, and throw when called on the other mode's grid.
Selection is tracked by the grid, not HaxeUI's `componentGroup`, which cannot express "none
selected". `dispose()` detaches the collapse listener - call it once the grid is done with.
`locked`/`lockReason` behave as on `ChoiceRow`.

### ToggleButton

A boolean as one full-width button that reads as a mode rather than a checkbox - for when "off"
is the normal state and "on" a distinct mode ("No time control"). It is a `ChoiceButton`, so
`EmphasisStyle` styles its on-state exactly as it does a selected choice:

```haxe
var noTimeControl:ToggleButton = new ToggleButton("No time control", on -> trace('on: $on'));
```

```haxe
public function new(caption:String, onToggle:Bool->Void, ?glyph:String, initiallyOn:Bool = false, initiallyEnabled:Bool = true)
public var on:Bool      // assigning renders without calling onToggle
public var enabled:Bool
```

Use a checkbox instead when the boolean is an attribute rather than a mode, and a two-option
`ChoiceRow` when both states deserve equal visual weight (rated/unrated). A disabled toggle shows
the disabled look when off and the muted locked-selected look (see `ChoiceButton`) when on.

### FieldGroup

A `surfaceSunken` inset box that groups fields belonging to one parameter - a row or a stack
depending on `direction`, optionally fixed-height whenever its contents can vary. A static
factory rather than a class a caller instantiates with `new`, since it needs to return a
genuine `HBox` or `VBox` depending on `direction` and Haxe has no way to extend either
conditionally - a `Box` with `layout` swapped after construction measured its own `percentWidth`
against its children's resolved size instead of the other way around, inflating the container
far past its intended 100% whenever a child itself had a `percentWidth`:

```haxe
public static function create(children:Array<Component>, direction:FieldGroupDirection = Vertical, ?fixedHeight:Int):Component
```

`FieldGroupDirection` (`haxefolio.form.plumbing`) is `Horizontal`/`Vertical`. It's set once by
the caller, not derived from `ResponsivityController.isCollapsed` - a layout choice, not a
responsive behaviour (contrast `ChoiceRow.stackOnCollapse` above, which is the latter kind).
Children top-align within `fixedHeight` by default, same as any other HaxeUI container - size
`fixedHeight` to actually match the content (or accept the slack) rather than picking a round
number, or unused space below top-aligned content can look like uneven padding.

### SteppedValueField<T\>

A `Stepper` under a `FieldHeader`, generic over the value type via a `parse`/`format` pair. The
header's right-aligned hint shows the constraint while the field is valid and swaps to the
failure reason, in red, when it isn't - the same reserved line either way, so validation
appearing is a colour change, not a layout change. Prefer the ready-made `IntField` and
`DurationField` below unless the value is neither a whole number nor a duration:

```haxe
public function new(
    label:String, value:T, onChange:T->Void, parse:String->Null<T>, format:T->String,
    step:T->Int->T, validate:T->FieldState<T>, hint:String, invalidFormatMessage:String,
    enabled:Bool = true, ?onValidityChange:Bool->Void
)
public var state(default, null):FieldState<T>;
public var currentValue(get, set):T;
public var valid(get, never):Bool;
public var enabled(default, set):Bool;
```

- **Invalid input is never reverted or clamped** - the user's keystrokes are theirs. The field
  marks itself and reports upward. `onChange` fires only for values that parsed *and*
  validated, so a host holding the last `onChange` value never holds an invalid one; a change in
  validity is reported through `onValidityChange` (and readable any time via `valid`/`state`),
  which is what a form uses to disable its primary action.
- **Errors show only after the field is touched** (edited or stepped by the user). A field that
  starts out invalid opens showing only its neutral `hint`.
- `validate` returns a whole `FieldState` for the signature's sake, but only `valid` and
  `message` matter: the field fills in `value` and `touched` itself, and `message` is shown only
  while invalid. Unparseable text shows `invalidFormatMessage`. Both must fit the header line -
  there is no `text-overflow: ellipsis` - roughly 22 label plus 14 hint/message characters in a
  288px half-width column.
- `step` gets the last known value and ±1 per button press and should keep its result in bounds
  itself: a button press has no "unparseable" case, so clamping there is unsurprising.
- Assigning `currentValue` re-renders and re-validates without calling `onChange`, but does
  call `onValidityChange` if validity flips - the hook for "presets plus custom" bindings where a
  neighbouring control drives the field. `percentWidth` defaults to 100; set it to place two
  fields side by side in a horizontal `FieldGroup`.

### IntField and DurationField

Ready-made `SteppedValueField<Int>`s, as static factories (`IntField.create(...)`,
`DurationField.create(...)`) rather than subclasses - HaxeUI's component macro rejects a
subclass whose constructor repeats its component superclass's parameter names:

```haxe
var bonus:SteppedValueField<Int> = IntField.create(
    "Bonus secs / turn", 5, value -> trace(value), 0, 120,
    "max 120", "not a number", "out of range"
);
var initial:SteppedValueField<Int> = DurationField.create(
    "Initial time", 300, seconds -> trace(seconds), 0, 21600,
    "max 6:00:00", "use m:ss", "out of range"
);
```

Both take `(label, value, onChange, min, max, hint, invalidFormatMessage, outOfRangeMessage,
enabled = true, ?onValidityChange)`; out-of-range typed input is marked with
`outOfRangeMessage`, never clamped, while the -/+ buttons clamp to `min`..`max`. `IntField`
accepts a decimal integer (optional leading `-`) and steps by 1. `DurationField` holds whole
seconds, accepts exactly `m:ss` (minutes unbounded) or `h:mm:ss` (two-digit minutes/seconds
below 60) and steps by 60 seconds; state the format in the label or hint, it is never inferred.
The parse/format pair is public as `haxefolio.form.plumbing.DurationFormat.parse`/`.format`.

### CommitTextField

A text input whose value applies on an explicit action - for inputs too expensive or too
error-prone to validate per keystroke. The one form component that defers its effect, and it
says so: its `HintLine` cycles through the idle instruction, the success confirmation and the
rejection reason (which also turns the input's border red):

```haxe
var position:CommitTextField = new CommitTextField(
    "Starting position", "", text -> trace('typed: $text'),
    text -> isValid(text) ? Applied : Rejected('Not a valid position'),
    "Apply", "Edit the value, then press Apply", "Position applied"
);
```

```haxe
public function new(
    label:String, initialText:String, onText:String->Void, onCommit:String->CommitResult,
    commitLabel:String, idleHint:String, appliedHint:String,
    commitTrigger:CommitTrigger = ButtonAndEnter, enabled:Bool = true
)
public var currentText(get, set):String;
public var enabled(default, set):Bool;
```

- `onCommit` *returns* `Applied` or `Rejected(message)` rather than throwing, so a host's
  validator stays a pure function. Keep `message` short - the hint line has no
  `text-overflow: ellipsis`.
- `onText` reports genuine user edits only, never an echo of assigning `currentText`; any edit
  also returns the hint line to `idleHint`, since the applied/rejected message described a value
  the field no longer holds. Assigning `currentText` renders without calling `onText` and resets
  the hint line the same way.
- `CommitTrigger` is `Button`, `Enter` or `ButtonAndEnter` (the default). With `Enter` the
  button is hidden and `commitLabel` unused - say so in `idleHint`. There is deliberately no
  blur trigger: HaxeFolio disables HaxeUI's `FocusManager`, so no focus-out is delivered, and a
  blur-commit would fire before the click on the button and commit twice.
- `enabled = false` disables the input and button and greys the label.
- The button follows `EmphasisStyle` like `ChoiceButton` does (solid fill by default,
  `haxefolio-emphasis-outlined` on an ancestor for the tinted-and-bordered look).

### PreviewPane

A caption row plus a fixed-size preview area for arbitrary host content - a rendered position, a
colour swatch, a generated image:

```haxe
var pane:PreviewPane = new PreviewPane(200, 200, boardWidget, "White to move");
pane.content = otherBoardWidget;
pane.caption = "Black to move";
```

```haxe
public function new(previewWidth:Int, previewHeight:Int, content:Component, ?caption:String, ?captionIcon:String)
public var caption(get, set):String;
public var content(get, set):Component;
```

- The area is always rendered at exactly `previewWidth` x `previewHeight` and clips
  (`clip: true`) rather than measuring around its content: content that doesn't fit is a design
  error to fix. **Don't add/remove the pane with a mode toggle** - it should show the effective
  value in every mode, including the default one; swap `content` instead. The pane itself
  is `previewWidth` wide, so a longer caption is cut off rather than widening it.
- The caption row (16px, then a 6px gap) is reserved whenever the pane is constructed with a
  `caption` or a `captionIcon`, even if the caption is later set to `""`, so changing it never
  moves the area. Constructed with neither, there is no caption row and using `caption` throws.
- Assigning `content` detaches the previous component *without disposing it*, so the host may
  keep and reuse it. The area does not position or size the content: give it a
  `percentWidth`/`percentHeight` of 100 to fill the area.

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

The same handlers also run when the preference's own LocalStorage entry changes from another same-origin tab or window - e.g. that tab's preference window, or its own app code calling `set`/`resetToDefault`/`setQuiet` - so a page reacting to `Preferences.language.onChange` stays in sync even when the change actually happened elsewhere. Per the DOM `storage` event this is built on, such reactions never fire for a change made by the current tab itself (browsers only dispatch the event to *other* browsing contexts) and never write back to LocalStorage, since the value already came from there - so no feedback loop is possible, same-tab or cross-tab.

### Preference storage

Values are persisted to LocalStorage under `<appSlug>.<id>` - namespaced by `HaxeFolioConfig.appSlug` so multiple HaxeFolio-based sites sharing the same origin (LocalStorage is scoped by origin, not by path, so this can happen even for unrelated sites on the same domain) don't collide. On load, each preference takes the value stored under its id, or its declared default if none is stored yet.

Removing a preference from the declaration leaves its LocalStorage entry in place; renaming one is equivalent to removing the old id and adding a new one, so the old value isn't inherited. Preference values aren't readable or writable before `HaxeFolioApp.init` has provided the storage backend.

The same namespaced LocalStorage access preferences are built on is also exposed directly, for a framework user's own arbitrary key-value data, via `HaxeFolioApp.valueStorage`:

```haxe
class StorageBackend
{
    public function has(id:String):Bool
    public function read(id:String):Null<String>
    public function write(id:String, value:String):Void
    public function remove(id:String):Void
    public function addExternalChangeHandler(id:String, callback:Null<String>->Void):Void
}
```

`has`/`read`/`write`/`remove` all key into the same `<appSlug>.<id>` namespace described above - `id` should therefore be chosen to avoid colliding with any declared preference's own `id`, since a colliding pair reads/writes the very same LocalStorage entry. As with preference values, `valueStorage` isn't available before `HaxeFolioApp.init` has run.

`addExternalChangeHandler(id, callback)` registers `callback` to run whenever `id`'s LocalStorage entry changes from another same-origin tab/window - the same cross-tab mechanism preferences themselves react through (see `Reacting to changes` above). `callback` receives the new raw string value, or `null` if the key was removed; per the same DOM `storage` event semantics, it never fires for a change made by the current tab itself. Multiple callbacks may be registered for the same `id`, all run once per matching native event, in unspecified order.

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
| `siteName` | `String` | Site name label text - see `Menu bar` for how it's interpreted. |
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

## Typography

HaxeFolio ships its own type rather than relying on a platform font stack - two self-hosted, Latin+Cyrillic WOFF2 families, exposed as theme vars: `uiFamily` (default **Onest**, weights 400/500/600) for all UI text, and `monoFamily` (default **IBM Plex Mono**, weights 400/500) for numeric values read digit-by-digit - clock readouts, ratings, notation strings - never for prose or labels, which would dilute that meaning.

Since a HaxeUI `font-name` rule loads one font file per weight rather than resolving weight within a family the way a browser's own `@font-face` does, each weight is its own var:

| Var | Default resource | Weight |
|---|---|---|
| `$ui-family-regular` | `haxefolio/fonts/Onest-Regular.woff2` | 400 |
| `$ui-family-medium` | `haxefolio/fonts/Onest-Medium.woff2` | 500 |
| `$ui-family-semibold` | `haxefolio/fonts/Onest-SemiBold.woff2` | 600 |
| `$mono-family-regular` | `haxefolio/fonts/IBMPlexMono-Regular.woff2` | 400 |
| `$mono-family-medium` | `haxefolio/fonts/IBMPlexMono-Medium.woff2` | 500 |

A component references one via `font-name: $ui-family-medium;` in its stylesheet, the same `$var` mechanism `$accent-color` and friends already use (see `Styling` below). A host substitutes a family by redeclaring the same var name(s), at whatever weights it uses, in its own `module.xml`:

```xml
<themes>
    <default>
        <var name="ui-family-medium" value="myapp/fonts/Archivo-Medium.woff2" />
    </default>
</themes>
```

An app's own module is processed after its library dependencies, so this overrides HaxeFolio's default with no further wiring - but a host must supply every weight it actually uses (substituting only `ui-family-medium` while leaving `ui-family-regular` at Onest mixes two faces on one label scale). Changing either family also invalidates every character budget below - HaxeUI has neither `letter-spacing` nor `text-overflow: ellipsis`, so a label's fit is measured against a specific face's advance widths, not estimated.

### Scale

| Role | Family | Size | Weight | Colour |
|---|---|---|---|---|
| Dialog / section title | ui | 17px | 600 | `ink` |
| Body text, button labels | ui | 13px | 500 | `ink` / `inkMuted` |
| Field label | ui | 12px | 500 | `inkMuted` |
| Numeric value | mono | 14px | 500 | `ink` |
| Hint, status, validation | ui | 11px | 400 | `inkMuted` / `danger` |

Field labels are sentence case, not mono uppercase - small mono caps read as administrative software, can't be tracked out without `letter-spacing`, and Cyrillic caps run particularly wide.

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

#### Form components

| Selector | Notes |
|---|---|
| `.haxefolio-field-header` | A `FieldHeader`'s row. |
| `.haxefolio-field-header-label` / `.haxefolio-field-header-label-locked` | Its label; the `-locked` variant applies whenever `locked == true`. |
| `.haxefolio-field-header-hint` / `.haxefolio-field-header-hint-error` | Its hint; the `-error` variant applies whenever `state == Error`. |
| `.haxefolio-hint-line` / `.haxefolio-hint-line-error` | A `HintLine`; same `-error` convention. |
| `.haxefolio-choice-button` / `:hover` / `:down` / `:disabled` | A `ChoiceButton`. `:down` is the selected state, `:disabled` the disabled one, `:down:disabled` a locked-but-selected one (see `ChoiceButton` above). |
| `.haxefolio-emphasis-outlined` | Ancestor class switching every `ChoiceButton`/`ToggleButton` beneath it from `Filled` to `Outlined` (see `ChoiceButton`). |
| `.haxefolio-choice-row` | A `ChoiceRow`'s own box. |
| `.haxefolio-stepper` | A `Stepper`'s row. |
| `.haxefolio-stepper-button` / `:hover` / `:disabled` | Its `-`/`+` buttons. |
| `.haxefolio-stepper-input` / `-invalid` / `:disabled` | Its text input; `-invalid` applies whenever `invalid == true`. |
| `.haxefolio-stepped-value-field` | A `SteppedValueField`'s own box (no default styling). |
| `.haxefolio-field-group` | A `FieldGroup`'s own box. `SwapSlot` carries no styling of its own - it's a bare `Stack`. |

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
