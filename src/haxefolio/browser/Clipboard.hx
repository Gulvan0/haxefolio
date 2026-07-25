package haxefolio.browser;

import js.lib.Promise;
import js.Browser;

class Clipboard
{
    public static function copy(text:String, ?onSuccess:Null<Void->Void>, ?onError:Null<Dynamic->Void>):Void
    {
        var promise:Promise<Dynamic> = Browser.navigator.clipboard.writeText(text);
        if (onError != null)
            promise.catchError(onError);
        if (onSuccess != null)
            promise.then(_ -> onSuccess());
    }
}
