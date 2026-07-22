package haxefolio.menu.builder;

import haxefolio.HaxeFolioApp;
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
}
