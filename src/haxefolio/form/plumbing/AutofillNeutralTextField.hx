package haxefolio.form.plumbing;

import haxe.ui.backend.html5.HtmlUtils;
import haxe.ui.components.TextField;
import haxe.ui.styles.Style;
import js.Browser;
import js.html.Element;
import js.html.StyleElement;

/*
    A TextField that browser autofill doesn't repaint. When Chrome autofills an input, its
    `:-webkit-autofill` rules paint a light-blue background and set the text to `FieldText`, both
    `!important`, so no stylesheet can override them - and HaxeUI stylesheets can't reach the
    pseudo-class anyway.

    HaxeUI paints the field's background and border on its own element; the native input inside it
    is transparent, and Chrome tints only that input. So the injected rule covers the tint with an
    inset shadow in the field's own background and sets the text fill to the field's own ink. Both
    colours come from HaxeUI's resolved style each time it is applied (theme, host overrides,
    `:disabled`), mirrored into CSS variables on this component's element, so nothing is hardcoded.

    The rules are injected once as a plain document stylesheet, keyed on a marker class this
    component puts on its own DOM element (as in ScrollArea).
*/
class AutofillNeutralTextField extends TextField
{
    private static inline var MARKER_CLASS:String = "haxefolio-autofill-neutral";
    private static inline var BACKGROUND_VARIABLE:String = "--haxefolio-autofill-background";
    private static inline var INK_VARIABLE:String = "--haxefolio-autofill-ink";

    private static var styleInjected:Bool = false;

    public function new()
    {
        super();

        injectStyleOnce();

        this.element.classList.add(MARKER_CLASS);
    }

    private override function applyStyle(style:Style):Void
    {
        super.applyStyle(style);

        if (style == null)
            return;

        var root:Element = this.element;

        // without a background of its own the field has nothing to cover the tint with, so it keeps Chrome's
        if (style.backgroundColor != null)
            root.style.setProperty(BACKGROUND_VARIABLE, HtmlUtils.colourWithOpacity(style.backgroundColor, style.backgroundOpacity));
        else
            root.style.removeProperty(BACKGROUND_VARIABLE);

        if (style.color != null)
            root.style.setProperty(INK_VARIABLE, HtmlUtils.color(style.color));
        else
            root.style.removeProperty(INK_VARIABLE);
    }

    private static function injectStyleOnce():Void
    {
        if (styleInjected)
            return;

        styleInjected = true;

        var style:StyleElement = Browser.document.createStyleElement();
        style.textContent = '
            .$MARKER_CLASS input:-webkit-autofill { -webkit-box-shadow: 0 0 0 1000px var($BACKGROUND_VARIABLE) inset; }
            .$MARKER_CLASS input:-webkit-autofill { -webkit-text-fill-color: var($INK_VARIABLE); caret-color: var($INK_VARIABLE); }
        ';
        Browser.document.head.appendChild(style);
    }
}
