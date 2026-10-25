package haxefolio.menu.builder;

import js.Browser;
import js.html.CSSStyleDeclaration;
import js.html.CanvasRenderingContext2D;
import js.html.Element;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.menu.MenuAction;

class MenuBuilderHelpers
{
    private static var measuringContext:Null<CanvasRenderingContext2D> = null;

    public static function invokeAction(action:MenuAction):Void
    {
        switch action
        {
            case NavigateTo(pathFactory):
                HaxeFolioApp.navigateTo(pathFactory());
            case Execute(fn):
                fn();
            case Link(url, newTab):
                Browser.window.open(url, newTab ? "_blank" : "_self");
        }
    }

    /**
        Resolves the initial label text for a menu/item/group: `explicitText` verbatim if given,
        otherwise the `implicitKey` locale key, in the same shape `LocaleUtils.localeBinding` produces.
    **/
    public static function resolveLabelText(explicitText:Null<String>, implicitKey:String):String
    {
        return explicitText ?? LocaleUtils.localeBinding(implicitKey);
    }

    /** The single-line width of `textElement`'s text in its computed font, rounded up as the browser rounds a text box's own width **/
    public static function measureSingleLine(textElement:Element):Float
    {
        if (measuringContext == null)
            measuringContext = Browser.document.createCanvasElement().getContext2d();

        var computedStyle:CSSStyleDeclaration = Browser.window.getComputedStyle(textElement);
        measuringContext.font = '${computedStyle.fontStyle} ${computedStyle.fontWeight} ${computedStyle.fontSize} ${computedStyle.fontFamily}';

        return Math.ceil(measuringContext.measureText(textElement.textContent).width);
    }
}
