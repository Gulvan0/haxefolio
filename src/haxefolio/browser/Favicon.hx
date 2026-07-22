package haxefolio.browser;

import js.Browser;
import js.html.LinkElement;

class Favicon
{
    public static var href(get, set):Null<String>;

    private static function get_href():Null<String>
    {
        var link:Null<LinkElement> = findLink();
        return link != null ? link.getAttribute("href") : null;
    }

    private static function set_href(value:Null<String>):Null<String>
    {
        if (value == null)
        {
            var link:Null<LinkElement> = findLink();

            if (link != null)
                link.removeAttribute("href");
        }
        else
            getOrCreateLink().href = value;

        return value;
    }

    private static function findLink():Null<LinkElement>
    {
        return cast Browser.document.querySelector("link[rel~='icon']");
    }

    private static function getOrCreateLink():LinkElement
    {
        var link:Null<LinkElement> = findLink();

        if (link == null)
        {
            link = cast Browser.document.createElement("link");
            link.rel = "icon";
            Browser.document.head.appendChild(link);
        }

        return link;
    }
}
