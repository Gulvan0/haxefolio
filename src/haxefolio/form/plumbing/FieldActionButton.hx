package haxefolio.form.plumbing;

import haxe.ui.containers.Box;
import haxe.ui.events.MouseEvent;
import js.Browser;
import js.html.Element;

/*
    A one-shot action button in a square lane at a TextInputField's right edge, as tall as the
    input, with a 16px glyph centred in it. Like PasswordRevealButton, the glyph is inline SVG drawn
    in `currentColor`; pressing it keeps focus where it is, and it stays out of the tab order.
*/
class FieldActionButton extends Box
{
    private static inline final GLYPH_SIZE:Int = 16;

    private final onActivate:Void->Void;

    /**
        `glyphPaths` is the markup inside a 16x16 viewBox, stroked 1.4 in `currentColor`; `label`
        is the accessible name.
    **/
    public function new(glyphPaths:String, label:String, onActivate:Void->Void)
    {
        super();

        this.onActivate = onActivate;
        this.addClass("haxefolio-text-input-action");

        var glyph:Element = Browser.document.createSpanElement();
        glyph.style.cssText = 'position: absolute; left: 50%; top: 50%; width: ${GLYPH_SIZE}px; height: ${GLYPH_SIZE}px; margin: -${GLYPH_SIZE >> 1}px 0 0 -${GLYPH_SIZE >> 1}px; pointer-events: none;';
        glyph.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="$GLYPH_SIZE" height="$GLYPH_SIZE" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" style="display: block;">$glyphPaths</svg>';
        this.element.appendChild(glyph);

        // keeps focus where it is: the input stays focused and its caret stays put
        this.element.addEventListener("mousedown", event -> event.preventDefault());
        this.element.setAttribute("role", "button");
        this.element.setAttribute("aria-label", label);
        this.element.setAttribute("title", label);
        this.registerEvent(MouseEvent.CLICK, _ -> activate());
    }

    private function activate():Void
    {
        if (!this.disabled)
            onActivate();
    }
}
