package haxefolio.menu.builder;

import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.menu.MenuAction;

class MenuBuilderHelpers
{
    public static function invokeAction(action:MenuAction):Void
    {
        switch action
        {
            case NavigateTo(pathFactory):
                HaxeFolioApp.navigateTo(pathFactory());
            case Execute(fn):
                fn();
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
}
