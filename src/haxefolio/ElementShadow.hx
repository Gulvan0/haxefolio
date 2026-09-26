package haxefolio;

import js.Browser;
import js.html.Element;
import js.html.StyleElement;

/*
    Elevation shadows for the framework's floating surfaces (overlay frames, the side bar, menu bar
    dropdowns). HaxeUI can't draw them: its `filter` style did not take effect from the stylesheet,
    and an inline `box-shadow` set on the element is cleared whenever HaxeUI re-applies the
    component's style. So each distinct shadow becomes a rule in a plain document stylesheet, keyed
    on a class put on the DOM element itself - which HaxeUI leaves alone, the same way ScrollArea
    styles its scrollbar.
*/
class ElementShadow
{
    private static var classNamesByShadow:Map<String, String> = [];
    private static var styleElement:Null<StyleElement> = null;

    /*
        Gives `element` the CSS `box-shadow` `shadow`, for as long as the element exists.
    */
    @:allow(haxefolio)
    private static function apply(element:Element, shadow:String):Void
    {
        element.classList.add(classNameFor(shadow));
    }

    private static function classNameFor(shadow:String):String
    {
        if (classNamesByShadow.exists(shadow))
            return classNamesByShadow.get(shadow);

        if (styleElement == null)
        {
            styleElement = Browser.document.createStyleElement();
            Browser.document.head.appendChild(styleElement);
        }

        var className:String = 'haxefolio-shadow-${Lambda.count(classNamesByShadow)}';
        classNamesByShadow.set(shadow, className);
        styleElement.textContent += '.$className { box-shadow: $shadow !important; }\n';

        return className;
    }
}
