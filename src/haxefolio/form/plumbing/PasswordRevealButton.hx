package haxefolio.form.plumbing;

import haxe.ui.containers.Box;
import haxe.ui.events.MouseEvent;
import haxefolio.LocaleUtils;
import js.Browser;
import js.html.Element;

/*
    The eye toggle of a RevealablePassword TextInputField: a square lane at the input's right edge,
    as tall as the input, with a 16px glyph centred in it - an eye while the text is hidden (the
    action is "show"), a struck-through eye while it is shown.

    The glyph is inline SVG drawn in `currentColor`, so the stylesheet recolours it through this
    component's `color` (which the backend puts on its element), per state, like any text. An image
    icon would need one file per colour per theme.

    Pressing it keeps focus (and the caret) in the input, and it stays out of the tab order, so the
    form's tab sequence is unchanged.
*/
class PasswordRevealButton extends Box
{
    private static inline final GLYPH_SIZE:Int = 16;

    private static inline final EYE_PATHS:String = '<path d="M1.5 8s2.4-4.5 6.5-4.5 6.5 4.5 6.5 4.5-2.4 4.5-6.5 4.5S1.5 8 1.5 8z"/><circle cx="8" cy="8" r="2"/>';
    private static inline final STRIKE_PATH:String = '<path d="M2.5 13.5l11-11"/>';

    private final glyph:Element;
    private final onToggle:Bool->Void;

    /**
        Whether the text is currently shown. Assigning renders it without calling `onToggle`.
    **/
    public var revealed(default, set):Bool;

    public function new(onToggle:Bool->Void)
    {
        super();

        this.onToggle = onToggle;
        this.addClass("haxefolio-password-reveal");

        glyph = Browser.document.createSpanElement();
        glyph.style.cssText = 'position: absolute; left: 50%; top: 50%; width: ${GLYPH_SIZE}px; height: ${GLYPH_SIZE}px; margin: -${GLYPH_SIZE >> 1}px 0 0 -${GLYPH_SIZE >> 1}px; pointer-events: none;';
        this.element.appendChild(glyph);

        // keeps focus where it is: the input stays focused and its caret stays put
        this.element.addEventListener("mousedown", event -> event.preventDefault());
        this.element.setAttribute("role", "button");
        this.registerEvent(MouseEvent.CLICK, _ -> toggle());

        this.revealed = false;
    }

    private function toggle():Void
    {
        if (this.disabled)
            return;

        revealed = !revealed;
        onToggle(revealed);
    }

    private function set_revealed(value:Bool):Bool
    {
        revealed = value;

        var paths:String = value ? EYE_PATHS + STRIKE_PATH : EYE_PATHS;
        glyph.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="$GLYPH_SIZE" height="$GLYPH_SIZE" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" style="display: block;">$paths</svg>';

        var labelKey:String = value ? "haxefolio.text_input.reveal.hide" : "haxefolio.text_input.reveal.show";
        this.element.setAttribute("aria-label", LocaleUtils.resolveText(LocaleUtils.localeBinding(labelKey)));
        this.element.setAttribute("aria-pressed", value ? "true" : "false");

        return value;
    }
}
