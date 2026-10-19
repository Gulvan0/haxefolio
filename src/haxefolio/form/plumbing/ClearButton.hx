package haxefolio.form.plumbing;

import haxe.ui.components.Button;
import haxefolio.LocaleUtils;
import js.Browser;
import js.html.Element;

/*
    The clear control of a SearchBar: a square lane at the input's right edge, as tall as the input,
    with a 16px cross centred in it. Like PasswordRevealButton, the glyph is inline SVG drawn in
    `currentColor`, and pressing it keeps focus (and the caret) in the input.

    A Button rather than a Box, so HaxeUI keeps its `:hover` state.
*/
class ClearButton extends Button
{
    private static inline final GLYPH_SIZE:Int = 16;

    public function new(onClear:Void->Void)
    {
        super();

        this.addClass("haxefolio-clear-button");

        var glyph:Element = Browser.document.createSpanElement();
        glyph.style.cssText = 'position: absolute; left: 50%; top: 50%; width: ${GLYPH_SIZE}px; height: ${GLYPH_SIZE}px; margin: -${GLYPH_SIZE >> 1}px 0 0 -${GLYPH_SIZE >> 1}px; pointer-events: none;';
        glyph.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="$GLYPH_SIZE" height="$GLYPH_SIZE" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" style="display: block;"><path d="M4 4l8 8M12 4l-8 8"/></svg>';
        this.element.appendChild(glyph);

        this.element.addEventListener("mousedown", event -> event.preventDefault());
        this.element.setAttribute("role", "button");
        this.element.setAttribute("aria-label", LocaleUtils.resolveText(LocaleUtils.localeBinding("haxefolio.search.clear")));
        this.onClick = _ -> onClear();
    }
}
