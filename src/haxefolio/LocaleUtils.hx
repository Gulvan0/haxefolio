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
        or suffix mixed with a binding), returns `key`, without the parameters a binding built by
        `localeBinding` may carry. Otherwise (a plain literal, or anything not shaped as a single
        whole-string binding) returns `null`.
    **/
    public static function extractLocaleKey(text:String):Null<String>
    {
        var parts:Null<Array<String>> = bindingParts(text);
        return parts != null ? parts[0] : null;
    }

    /**
        Resolves `text` the same way a HaxeUI `.text` property does, but as a one-shot value
        rather than a live component binding: a literal by default, or - if `text` is exactly one
        `{{key}}` binding (see `extractLocaleKey`) - the locale string for `key`, with `[0]`-`[3]`
        substituted per `LocaleManager.lookupString`: first by the parameters the binding carries
        (a quoted one unquoted, e.g. `{{key, 'Some name', 5}}`), then by `param0`-`param3`
        (ignored for a literal).
    **/
    public static function resolveText(text:String, ?param0:Any, ?param1:Any, ?param2:Any, ?param3:Any):String
    {
        var parts:Null<Array<String>> = bindingParts(text);
        if (parts == null)
            return text;

        var params:Array<Any> = [for (i in 1...parts.length) unquote(parts[i])];
        for (param in [param0, param1, param2, param3])
            params.push(param);

        return LocaleManager.instance.lookupString(parts[0], params[0], params[1], params[2], params[3]);
    }

    // the key and the parameter expressions of a whole-string binding, split on the commas outside quotes
    private static function bindingParts(text:String):Null<Array<String>>
    {
        if (text == null || !text.startsWith("{{") || !text.endsWith("}}"))
            return null;

        if (text.indexOf("{{", 2) != -1)
            return null;

        var body:String = text.substring(2, text.length - 2);
        var parts:Array<String> = [];
        var start:Int = 0;
        var quote:Null<String> = null;

        for (i in 0...body.length)
        {
            var char:String = body.charAt(i);
            if (quote != null)
            {
                if (char == quote)
                    quote = null;
            }
            else if (char == "'" || char == '"')
                quote = char;
            else if (char == ",")
            {
                parts.push(body.substring(start, i).trim());
                start = i + 1;
            }
        }
        parts.push(body.substring(start).trim());

        return parts;
    }

    private static function unquote(expression:String):String
    {
        var quoted:Bool = expression.length >= 2 && (expression.startsWith("'") && expression.endsWith("'") || expression.startsWith('"') && expression.endsWith('"'));
        return quoted ? expression.substring(1, expression.length - 1) : expression;
    }
}
