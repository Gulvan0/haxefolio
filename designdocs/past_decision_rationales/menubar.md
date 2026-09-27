# HaxeFolio menubar

The app-wide top bar and its narrow-class sidebar.
Colours and type come from `haxefolio-theme.md`. This file only adds what the bar introduces.

Built on HaxeUI's `MenuBar` / `Menu` / `MenuItem` (skinned, not reimplemented, per the
generalization plan). The sidebar is not an overlay: it does not go through `present` and
has its own rules (§2). It is not a HaxeUI `SideBar` either, but HaxeFolio's own edge panel (§0).

```
Wide    [ SiteName ]  [ Menu ] [ Menu ] [ Menu ]  ─────────  [ Widget ] [ Widget ]
Narrow  [ ☰ ] [ SiteName ]  ──────────────────────────────  [ persistent Widget… ]
```

## 0. Prerequisite: shared edge panel

Done as its own step, before this rework. HaxeFolio stops using HaxeUI's `SideBar` altogether and
gets one edge panel component, used by both the menu sidebar and the overlay sheet
(`SheetPresentation`):

| | Menu sidebar | Overlay sheet |
| --- | --- | --- |
| Edge | left | bottom |
| Size | `sidebarWidth` × full height | full viewport |
| Scrim | visible; tapping it closes the sidebar | only visible while sliding; tapping does nothing (overlay rule) |
| Close without animation | on crossing to Wide | not needed |

- The panel owns its scrim, the slide, its open / closing / gone states and a single "gone" callback.
  The scrim stays until the panel is gone, so nothing beneath is reachable mid-slide.
- The slide is a CSS `transform` transition set on the panel's DOM element, and the scrim fade an
  `opacity` transition on its own element: both `cubic-bezier(.2,.8,.2,1)`, 260 ms for the slide and
  220 ms for the fade. The same values apply to the sheet.
- The panel does not freeze the page underneath (HaxeUI's `SideBar.show()` did), and shares no state
  with any other panel.
- Overlay-only behaviour (`inert`, Esc, one-at-a-time) stays in `OverlayController`.
- `MenuFacade.sideBar` changes type from `SideBar` to the new component; the README's description
  of the sheet and the side bar is updated to match.

## 1. Geometry

| Value | Default | Notes |
| --- | --- | --- |
| `menuBarHeight` | 52 | both width classes; the sidebar header repeats it |
| `menuBarPadding` | Wide: 22 both sides. Narrow: 4 left, 8 right | Wide matches `padding`; Narrow is tight so the 44 targets sit near the edges |
| `menuBarGap` | 26 / 4 | Wide: after the site name. Narrow: between hamburger, name, widgets |
| `menuTriggerHeight` | 34 | menu label button |
| `dropdownRowHeight` | 36 | `MenuItem` in a dropdown |
| `dropdownMinWidth` | 232 | menu dropdowns |
| `sidebarWidth` | 320 | capped at viewport − 56 so scrim stays tappable |
| `sidebarRowHeight` | 44 | touch floor |

### 1.1 Bar

- Fill `surface`, bottom 1 px `border`. Page background sits below `surface` (elevation rule, `haxefolio-theme.md` §2.2).
- Children vertically centred.

### 1.2 Site name

- **Jost 600, 21 px, `ink`**, line-height 1. Self-hosted WOFF2, Latin + Cyrillic, alongside Onest and Plex Mono.
- No hover change.
- Jost is used only here. It is not a third UI family, and the mono/proportional split (`haxefolio-theme.md` §6) is unaffected.
- Jost replaces the currently shipped Futura (`Futura.ttf`, `FuturaItalic.ttf` are removed). It is exposed as a
  theme var, like the other families, so a host can substitute it, and ships with its OFL licence.
- Chosen over Futura: same geometry, open licence, can be shipped. Alternatives reviewed: Onest 700, Unbounded 600, Spectral 600.

### 1.3 Menu trigger

| State | Fill | Border | Label |
| --- | --- | --- | --- |
| Rest | transparent | transparent | `inkMuted`, 13 / 500 |
| Hover | `surfaceSunken` | transparent | `ink` |
| Open | `surfaceSunken` | `border` | `ink` |

Padding 0 11 px 0 12 px, radius 5 px, gap 8 px to the chevron. Menu triggers are 2 px apart.
Chevron: 5 × 5 px, 1.5 px right and bottom stroke in `inkFaint`, rotated 45° (down) at rest and
225° (up) when open. HaxeUI has no rotated borders, so ship it as a 10 px image asset with two states.

### 1.4 Dropdown

- Fill `surface`, 1 px `border`, radius 8 px except the top corner next to the trigger, which is square (top-left normally; top-right when HaxeUI right-aligns a dropdown that would overflow the screen), shadow `0 8px 28px rgba(24,26,31,0.16)` (Wide overlay elevation).
- Opens directly below its trigger with no gap, attached to it the way HaxeUI draws it (including HaxeUI's filler joining it to the trigger).
- Padding 6 px, rows 2 px apart. Left edge aligned to the trigger.
- Row: 36 px, padding 0 10 px, radius 5 px, icon 16 px box, gap 10 px, label 13 / 500 `ink`.
- Row hover: `surfaceSunken`.
- Labels are single-line; budget against `dropdownMinWidth` − 54 px (≈ 27 Latin / 25 Cyrillic chars at 13 px). No truncation.

## 2. Sidebar (Narrow)

- Slides from the left: `translateX(-100%)` → `0`, 260 ms, `cubic-bezier(.2,.8,.2,1)`. Scrim fades in over 220 ms.
- Fill `surface`, right 1 px `border`, shadow `4px 0 20px rgba(24,26,31,0.18)`, full viewport height.
- Scrim `scrim` covers the whole viewport, including the bar. Tapping it closes the sidebar.

### 2.1 Relation to overlays

The sidebar is separate from the overlay system. It borrows some of an overlay's behaviour, but not
its one-at-a-time slot:

- While it is open, the rest of the app is `inert`.
- `Esc` closes it.
- Navigating closes it.
- A click outside it (on the scrim) closes it.
- It does not block `present`: an overlay can be presented while the sidebar is open or closing.
- No drag.

### 2.2 Header

The header repeats the bar row exactly: height `menuBarHeight`, same padding, same gap. As a
result, the hamburger and site name sit at identical coordinates open and closed. Bottom hairline is
`divider`.

- Hamburger target: 44 × 44 px, radius 6 px; bars are 18 × 2 px, 4 px apart, `inkMuted`. Pressed: `surfaceSunken`.
- While open, the glyph becomes **✕** (17 px, `inkMuted`) in the same box. The target does not move,
  and the glyph states what the tap will do. This is fixed, not configurable.
- Navigating via the site name closes the sidebar.
- Persistent widgets are not repeated in the header. They remain visible, dimmed, under the scrim.

### 2.3 Body

A scroll region (vertical, `overscroll-behavior: contain`, reserved 10 px gutter) with padding
4 px top, 22 px bottom. Items are grouped by menu, in bar order, followed by the `sidebarExtras`
groups, which are styled the same.

Flat; every item is one tap away.
- Group: padding 14 8 6 8. Groups after the first get a `divider` top hairline.
- Group label: menu (or extra group) name, 12 / 500 `inkMuted`, sentence case (field-label style), padding 0 14 6.
- Row: 44 px, padding 0 14 px, radius 6 px, icon 16 px, gap 12 px, 13 / 500 `ink`. Pressed `surfaceSunken`.
- Row icons mirror the menu items' icons, so `MenuFacade.updateMenuItemIcon` updates the bar and the sidebar together.

Selecting any item closes the sidebar and runs the item's action straight away, without waiting for
the slide-out. The same applies to the site name. An overlay presented by the action appears over the
closing sidebar.

## 3. Behaviour summary

- Dropdowns close on outside click, item selection, `Esc`, or a width-class change.
- Crossing to Wide while the sidebar is open closes it without animation.
- Icons are host images in a 16 px box

## 4. Implementation notes

1. **Closing a dropdown from code.** Esc and width-class changes are not handled by HaxeUI. Track
   the open menu through `MenuBar.onMenuOpened`/`onMenuClosed`, and close it with
   `MenuBar.closeCurrentMenu()`, from a document `keydown` listener (Esc) and a `ResponsivityController`
   breakpoint subscription. `closeCurrentMenu()` is new in haxeui-core: upstream PR
   https://github.com/haxeui/haxeui-core/pull/715, fork PR https://github.com/Gulvan0/haxeui-core/pull/4.
   Do not use `Menu.closePopup()`: it leaves the menubar treating the menu as open.
2. **Trigger styling through CSS only.** The bar's trigger buttons are proxies `MenuBar` builds and
   keeps in its private `_buttons`. Style them through `.haxefolio-menubar > .menubar-button` (open
   = `:down`), including the chevron. Anything set from code would need the Reflect hack
   `MenuFacade` already uses and breaks silently on a haxeui-core upgrade.
3. **Gaps through margins.** `MenuBar` only turns direct `Menu` children into triggers and refuses
   `addComponentAt`/`removeComponent`/reordering, so items cannot be grouped into nested boxes.
   Use `horizontalSpacing` 2 (between triggers) and per-class margins for the other gaps (e.g. after
   the site name). Relies on the margin handling fixed by haxeui-core PRs #706/#707.
4. **Shadows on the DOM element.** HaxeUI's `filter`/`clip` do not take effect from the stylesheet,
   so the dropdown and sidebar shadows are set on the element directly, as overlays do. The dropdown
   is removed from the screen when it closes and re-added when it opens, so its shadow must be
   re-applied on every `onMenuOpened`, not once at build time.
5. **End of the slide.** The panel is gone when its `transitionend` fires, with a timer as a
   backup in case the browser never fires it. Closing without animation skips the transition and
   goes straight to gone.
6. **Shared `inert`.** The sidebar and `OverlayController` both mark the app root `inert`. Track who
   holds it and clear it only when neither does; otherwise the sidebar finishing its close would
   make an open overlay non-modal.
7. **Esc priority.** With an overlay open over the sidebar, one Esc closes only the overlay: the
   sidebar's handler ignores Esc while an overlay is open.
8. **Computed values.** Colours, type and plain geometry live in the stylesheet. One value needs
   code: the `sidebarWidth` cap (viewport − 56), recomputed on resize.

## 5. Build order

Each step builds on the previous one and ends in a state that compiles and runs. Verify every step
in the sample, at both widths, before moving on.

### Phase A: shared edge panel (§0)

1. **Edge panel component.** Scrim, slide and fade transitions, open / closing / gone states, the
   "gone" callback with its timer backup, instant close, resize. Nothing uses it yet.
2. **Move the overlay sheet onto it.** Rewrite `SheetPresentation` on the edge panel.
   Check: the preference window as a sheet opens and closes, Esc, navigating away while it is open,
   resizing while open, crossing the breakpoint while open (it stays a sheet), nothing beneath is
   clickable mid-slide.
3. **Shared `inert` ownership** (note 6). `OverlayController` goes through it; behaviour unchanged.
   Check: dialog and sheet are still modal.
4. **Move the menu sidebar onto it.** `SideBarBuilder`, `MenuFacade.sideBar`'s type,
   `HaxeFolioApp`, `ResponsivityController`. Add the §2.1 behaviour: `inert`, Esc (with the note 7
   priority), close on navigation and on a scrim tap, instant close on crossing to Wide, item
   actions run straight away. Old styling is fine at this point.
   Check: opening an overlay from a sidebar item (e.g. preferences) while the sidebar closes; Esc
   with both open closes only the overlay; the overlay stays modal after the sidebar is gone.
5. **README for Phase A.** The sheet and side bar descriptions, `MenuFacade.sideBar`. Phase A can
   be committed on its own.

### Phase B: reskin

6. **Jost.** WOFF2 files and OFL licence, the theme var, remove Futura, site name style (§1.2).
7. **Bar.** Fill and border, height, padding and gaps (note 3), hamburger target and glyph.
8. **Menu triggers.** Trigger states in CSS (note 2), chevron asset with two states.
9. **Dropdown.** Frame, rows, minimum width, the shadow re-applied on every open (note 4), the
   square corner. For the right-aligned case, detect the flip on `onMenuOpened` by comparing the
   dropdown's and trigger's left edges, since HaxeUI does not expose it.
10. **Closing dropdowns from code** (note 1): Esc and width-class changes via `closeCurrentMenu()`.
11. **Sidebar content.** Header repeating the bar row with the ✕, body in a `ScrollArea`, groups and
    rows, row icons, and `MenuFacade.updateMenuItemIcon` updating both.
12. **README for Phase B.** Typography (Jost), CSS classes table, `updateMenuItemIcon`, side bar icons.
    Final pass in the sample at both widths.

### Dependency

Step 10 needs `MenuBar.closeCurrentMenu()`. It is in the local haxeui-core checkout as an
uncommitted change; merge fork PR https://github.com/Gulvan0/haxeui-core/pull/4 before committing
step 10, or anyone else building HaxeFolio against the fork will not have it.
