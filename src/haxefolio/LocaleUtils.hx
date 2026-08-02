package haxefolio;

import haxe.ui.locale.LocaleManager;

using StringTools;

class LocaleUtils
{
    /**
        Wraps `key` as a `{{key}}` binding - the form a HaxeUI `.text` property resolves as a locale
        key rather than a literal.
    **/
    public static function localeBinding(key:String, ?paramExpr0:String, ?paramExpr1:String, ?paramExpr2:String, ?paramExpr3:String):String
    {
        var wrapped:String = key;
        for (expr in [paramExpr0, paramExpr1, paramExpr2, paramExpr3])
            if (expr != null)
                wrapped += ', $expr';
            else
                break;
        return '{{$wrapped}}';
    }

    /**
        If `text` consists of exactly one `{{key}}` binding (the whole string, not a literal prefix
        or suffix mixed with a binding), returns `key`. Otherwise (a plain literal, or anything not
        shaped as a single whole-string binding) returns `null`.
    **/
    public static function extractLocaleKey(text:String):Null<String>
    {
        if (text == null || !text.startsWith("{{") || !text.endsWith("}}"))
            return null;

        if (text.indexOf("{{", 2) != -1)
            return null;

        return text.substring(2, text.length - 2);
    }

    /**
        Resolves `text` the same way a HaxeUI `.text` property does, but as a one-shot value
        rather than a live component binding: a literal by default, or - if `text` is exactly one
        `{{key}}` binding (see `extractLocaleKey`) - the locale string for `key`, with `param0`-
        `param3` substituted for `[0]`-`[3]` per `LocaleManager.lookupString` (ignored otherwise).
    **/
    public static function resolveText(text:String, ?param0:Any, ?param1:Any, ?param2:Any, ?param3:Any):String
    {
        var key:Null<String> = extractLocaleKey(text);
        return key != null ? LocaleManager.instance.lookupString(key, param0, param1, param2, param3) : text;
    }
}
