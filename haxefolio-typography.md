# HaxeFolio typography

Framework-level typography: the shipped faces, the scale, the proportional/mono split,
and the character-budget rule that replaces text truncation. Component specs reference
this file rather than restating it.

HaxeFolio targets HTML5 only, so the framework **ships its faces** rather than relying on
platform stacks. That is not a convenience choice — see §4.

## 1. Default families

| Token | Default | Weights | Licence |
| --- | --- | --- | --- |
| `uiFamily` | **Source Sans 3** | 400, 500, 600 | SIL OFL |
| `monoFamily` | **IBM Plex Mono** | 400, 500 | SIL OFL |

Self-hosted WOFF2, Latin + Cyrillic subsets, about 90 KB total for the five files.

Why this pair:

- **Cyrillic is drawn, not extrapolated.** Adobe cut Source Sans's Cyrillic properly, so
  character budgets (§4) hold in Russian as well as in English. This is the deciding
  factor for a framework whose hosts are not all anglophone.
- **A real 600 weight**, so semibold titles and selected labels never fall back to
  synthetic bold — faux-bold advances differ from the real thing, which quietly breaks
  every budget.
- **Neutral without being the default look.** Source Sans does not stamp a voice on
  downstream sites, but it also does not look like an unstyled page, which the
  Inter/Roboto pair increasingly does.
- **Plex Mono is the better numeric face:** unambiguous 1/l/I and 0/O, which is what a
  clock readout or a notation string actually needs.

Rejected, and why:

- **Platform stacks** (`system-ui` and friends) — free and zero-payload, but they make
  character budgets impossible (§4). This was the original default and is now the
  fallback chain only.
- **Noto Sans / Noto Sans Mono** — the safest possible pick, complete coverage, but
  characterless to the point of looking unstyled. Still the right choice for a host that
  wants maximum script coverage.
- **PT Sans / PT Mono** — ParaType drew it Cyrillic-first, so it is the best option for a
  host whose primary locale is Russian. Reads slightly dated in Latin, which is the only
  reason it is not the default.
- **Inter** — the current default look of unstyled web software; adopting it makes every
  HaxeFolio site look like every other web app.

The declared stack keeps the platform families **as a fallback chain only**:

```
uiFamily:   "Source Sans 3", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif
monoFamily: "IBM Plex Mono", ui-monospace, "Cascadia Mono", "Roboto Mono", monospace
```

A failed font load therefore degrades instead of breaking — but budgets are void in that
state, so treat a font-load failure as a real error, not a cosmetic one.

## 2. The proportional/mono split is semantic

`monoFamily` is for **numeric values only** — clock readouts, short numeric labels,
notation strings, ratings, IDs. Mono means "this is a value you read digit by digit".
Using it for prose or for labels dilutes that and is the single easiest way to make a
product look like a developer tool.

A host may substitute either family, but must keep the split.

## 3. Scale

| Role | Family | Size | Weight | Colour |
| --- | --- | --- | --- | --- |
| Dialog / section title | ui | 17 px | 600 | `ink` |
| Body text, button labels | ui | 13 px | 500 | `ink` / `inkMuted` |
| Field label | ui | 12 px | 500 | `inkMuted` |
| Numeric value | mono | 14 px | 500 | `ink` |
| Hint, status, validation | ui | 11 px | 400 | `inkMuted` / `danger` |

Field labels are **sentence case, not mono uppercase**. Three reasons, in order of
weight: small mono caps are the visual signature of administrative software and make
every dialog read as a settings console; without `letter-spacing` (§4) untracked small
caps look cramped; and Cyrillic caps run wide, so uppercase labels are the first thing to
overflow in Russian.

## 4. No truncation — labels fit by construction

Two HaxeUI constraints shape everything above:

- **No `letter-spacing`.** Tracked-out caps are impossible, which is a second reason
  labels are sentence case — that style needs no tracking to look right. Never
  substitute manual space-between-letters strings.
- **No `text-overflow: ellipsis`.** Overflowing text is clipped by the container's
  `overflow: hidden`, which looks broken. Labels must therefore be short enough to fit
  by construction.

**This is why the framework ships a font.** Per-character advance differs by roughly 3–6%
between Segoe UI, SF, Roboto and the common Linux defaults, so a label budgeted against a
platform stack fits on one operating system and clips on another. A character budget is
only meaningful against a known face. Shipping `uiFamily` is what makes budgets true
statements rather than estimates.

Average advance for mixed-case text, derived from Source Sans 3's metrics:

| Size | Latin | Cyrillic |
| --- | --- | --- |
| 11 px | 5.4 px/char | 5.9 px/char |
| 12 px | 5.9 px/char | 6.4 px/char |
| 13 px | 6.4 px/char | 6.9 px/char |
| 17 px | 8.4 px/char | 9.1 px/char |

Cyrillic runs about 8% wider; budget against the Cyrillic column when the product is
localised into Russian. These are averages, not guarantees — verify in the browser any
label that clears its budget by less than 10%.

### 4.1 Rules for budgeting

1. **Every control with a known width states a character budget** in its component spec,
   and translators are given that number.
2. Where a translation will not fit, **shorten the term rather than abbreviating with a
   trailing dot.** A full short word always reads better than a contraction — Russian
   «Любые» over «Случ.».
3. Any row of **three or more equal-width controls** with locale-dependent labels
   **stacks vertically on mobile** rather than shrinking, so each label gets the full
   width.
4. Prefer a layout that cannot overflow to a budget that might. Stacking, wrapping and
   percentage widths are all cheaper than policing translations.

## 5. Overriding a family is its own class of override

Component specs divide overrides into themeable colour and non-themeable geometry.
Typography is neither:

> **Changing `uiFamily` or `monoFamily` invalidates every character budget.** A host
> that substitutes a face must re-measure and restate its own budgets; it must not
> inherit the framework's numbers.

A host should also confirm its face has a true 600 and real Cyrillic before adopting it.
Intellector, for example, overrides `uiFamily` to Archivo and `monoFamily` to IBM Plex
Mono, and owns its own measured budgets as a result.
