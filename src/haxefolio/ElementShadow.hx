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

    Rules are never removed from the stylesheet, so the set of distinct shadow strings an app uses
    should be small and fixed (constants), not computed per element.
**/
class ElementShadow
{
    private static var classNamesByShadow:Map<String, String> = [];
    private static var styleSheet:Null<CSSStyleSheet> = null;

    /**
        Gives `element` the CSS `box-shadow` `shadow` (e.g. `"0 8px 28px rgba(42, 33, 26, 0.16)"`).
        The shadow stays for as long as the element exists, unless the returned handle's `detach()`
        is called, which removes it from this element again (safe to call more than once).
    **/
    public static function apply(element:Element, shadow:String):Detachable
    {
        var className:String = classNameFor(shadow);
        element.classList.add(className);

        return new Detachable(() -> element.classList.remove(className));
    }

    private static function classNameFor(shadow:String):String
    {
        if (classNamesByShadow.exists(shadow))
            return classNamesByShadow.get(shadow);

        // The value is written into a stylesheet rule, so anything that could close it early is out.
        if (~/[{};]/.match(shadow))
            throw 'Invalid box-shadow value: $shadow';

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
}
