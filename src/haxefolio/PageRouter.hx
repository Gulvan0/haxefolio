package haxefolio;

import js.Browser;

using StringTools;

typedef PageResolution = {
    definition:PageDefinition,
    params:Map<String, String>
}

class PageRouter
{
    public static var defaultPageDefinition(default, null):PageDefinition;

    private static var pages:Array<PageDefinition>;

    public static function init(pages:Array<PageDefinition>):Void
    {
        PageRouter.pages = pages;
        defaultPageDefinition = findDefaultPageDefinition(pages);
    }

    public static function resolve(path:String):Null<PageResolution>
    {
        for (definition in pages)
        {
            var params:Null<Map<String, String>> = PagePathMatcher.match(definition.path, path);

            if (params != null)
                return {definition: definition, params: params};
        }

        return null;
    }

    public static function readPathFromUrl():Null<String>
    {
        var search:String = Browser.window.location.search;

        for (pair in search.substring(1).split("&"))
            if (pair.startsWith("p="))
                return pair.substring(2);

        return null;
    }

    public static function readFragmentFromUrl():Null<String>
    {
        var hash:String = Browser.window.location.hash;

        return hash.length > 0 ? hash.substring(1) : null;
    }

    public static function pushUrl(path:String, ?state:Dynamic, ?fragment:String):Void
    {
        Browser.window.history.pushState(state, "", buildUrl(path, fragment));
    }

    public static function replaceUrl(path:String, ?state:Dynamic, ?fragment:String):Void
    {
        Browser.window.history.replaceState(state, "", buildUrl(path, fragment));
    }

    private static function buildUrl(path:String, ?fragment:String):String
    {
        var url:String = '${Browser.window.location.pathname}?p=$path';

        return fragment != null ? '$url#$fragment' : url;
    }

    private static function findDefaultPageDefinition(pages:Array<PageDefinition>):PageDefinition
    {
        var defaultPages:Array<PageDefinition> = pages.filter(page -> page.isDefault == true);

        if (defaultPages.length != 1)
            throw 'HaxeFolio config must mark exactly one page as default, found ${defaultPages.length}.';

        var page:PageDefinition = defaultPages[0];

        if (page.path.indexOf("{") != -1)
            throw 'The default page\'s path ("${page.path}") must not contain parameters.';

        return page;
    }
}
