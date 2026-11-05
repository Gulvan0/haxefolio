package haxefolio;

class PagePathMatcher
{
    /**
        The parameters of `path`, URL-decoded, if it fits `template`; null otherwise.
        Decoded per segment, so an encoded `/` stays within its parameter.
    **/
    public static function match(template:String, path:String):Null<Map<String, String>>
    {
        var templateSegments:Array<String> = template.split("/");
        var pathSegments:Array<String> = path.split("/");

        if (templateSegments.length != pathSegments.length)
            return null;

        var params:Map<String, String> = [];

        for (i in 0...templateSegments.length)
        {
            var templateSegment:String = templateSegments[i];
            var pathSegment:String = pathSegments[i];

            if (StringTools.startsWith(templateSegment, "{") && StringTools.endsWith(templateSegment, "}"))
            {
                var value:Null<String> = decodeSegment(pathSegment);
                if (value == null)
                    return null;
                params.set(templateSegment.substring(1, templateSegment.length - 1), value);
            }
            else if (templateSegment != pathSegment)
                return null;
        }

        return params;
    }

    /** Null if `segment` isn't validly encoded **/
    private static function decodeSegment(segment:String):Null<String>
    {
        try
        {
            return StringTools.urlDecode(StringTools.replace(segment, "+", "%2B")); // `urlDecode` reads `+` as a space, as in a form; here it stands for itself
        }
        catch (_)
        {
            return null;
        }
    }
}
