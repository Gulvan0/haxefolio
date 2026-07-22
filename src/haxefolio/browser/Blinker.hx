package haxefolio.browser;

import js.Browser;

class Blinker
{
    public static inline var DEFAULT_INTERVAL:Int = 1000;

    private var alternateTitle:String;
    private var alternateFaviconHref:Null<String>;
    private var intervalMs:Int;
    private var baseTitle:String;
    private var baseFaviconHref:Null<String>;
    private var showingAlternate:Bool;
    private var timerId:Null<Int>;

    public var isActive(get, never):Bool;

    public function new(alternateTitle:String, ?alternateFaviconHref:String, intervalMs:Int = DEFAULT_INTERVAL)
    {
        this.alternateTitle = alternateTitle;
        this.alternateFaviconHref = alternateFaviconHref;
        this.intervalMs = intervalMs;
    }

    public function start():Void
    {
        stop();

        baseTitle = Browser.document.title;
        baseFaviconHref = Favicon.href;
        showingAlternate = false;
        timerId = Browser.window.setInterval(tick, intervalMs);
    }

    public function stop():Void
    {
        if (timerId == null)
            return;

        Browser.window.clearInterval(timerId);
        timerId = null;
        Browser.document.title = baseTitle;

        if (alternateFaviconHref != null)
            Favicon.href = baseFaviconHref;
    }

    private function tick():Void
    {
        showingAlternate = !showingAlternate;
        Browser.document.title = showingAlternate ? alternateTitle : baseTitle;

        if (alternateFaviconHref != null)
            Favicon.href = showingAlternate ? alternateFaviconHref : baseFaviconHref;
    }

    private function get_isActive():Bool
    {
        return timerId != null;
    }
}
