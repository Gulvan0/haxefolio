package haxefolio;

import js.Browser;
import js.html.CSSStyleSheet;
import js.html.Element;
import morestd.Detachable;

/**
    Elevation shadows for floating surfaces (overlay frames, the side bar, menu bar dropdowns, and
    any host component that floats over the page).

    HaxeUI can't draw them: its `filter` style did not take effect from the stylesheet, and an
    inline `box-shadow` set on the element is cleared whenever HaxeUI re-applies the component's
    style. So each distinct shadow becomes a rule in a plain document stylesheet, keyed on a class
    put on the DOM element itself - which HaxeUI leaves alone, the same way ScrollArea styles its
    scrollbar.

    Rules are never removed from the stylesheet, so the set of distinct shadows an app uses should
    be small and fixed (constants), not computed per element.
**/
class ElementShadow
{
    private static var classNamesByShadow:Map<String, String> = [];
    private static var styleSheet:Null<CSSStyleSheet> = null;

    /**
        Gives `element` the shadow `shadow`. It stays for as long as the element exists, unless the
        returned handle's `detach()` is called, which removes it from this element again (safe to
        call more than once).
    **/
    public static function apply(element:Element, shadow:Shadow):Detachable
    {
        var className:String = classNameFor(toCss(shadow));
        element.classList.add(className);

        return new Detachable(() -> element.classList.remove(className));
    }

    private static function classNameFor(shadow:String):String
    {
        if (classNamesByShadow.exists(shadow))
            return classNamesByShadow.get(shadow);

        if (styleSheet == null)
        {
            var styleElement = Browser.document.createStyleElement();
            Browser.document.head.appendChild(styleElement);
            styleSheet = cast styleElement.sheet;
        }

        var className:String = 'haxefolio-shadow-${Lambda.count(classNamesByShadow)}';
        classNamesByShadow.set(shadow, className);
        styleSheet.insertRule('.$className { box-shadow: $shadow !important; }', styleSheet.cssRules.length);

        return className;
    }

    private static function toCss(shadow:Shadow):String
    {
        var red:Int = (shadow.color >> 16) & 0xFF;
        var green:Int = (shadow.color >> 8) & 0xFF;
        var blue:Int = shadow.color & 0xFF;
        var spread:Float = shadow.spread ?? 0.0;

        return '${shadow.offsetX}px ${shadow.offsetY}px ${shadow.blur}px ${spread}px rgba($red, $green, $blue, ${shadow.opacity})';
    }
}
