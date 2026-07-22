package haxefolio;

class PagePathMatcher
{
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
                params.set(templateSegment.substring(1, templateSegment.length - 1), pathSegment);
            else if (templateSegment != pathSegment)
                return null;
        }

        return params;
    }
}
