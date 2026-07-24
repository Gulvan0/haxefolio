package haxefolio.browser;

import morestd.DateTime;
import js.html.Event;
import js.Browser;

class ActivityTracker
{
    private static var lastActivityTs:Int;

    public static function activate()
    {
        for (eventKind in ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart'])
            Browser.document.addEventListener(eventKind, updateTs);
    }

    public static function getLastActivityTs():Int
    {
        return lastActivityTs;
    }

    private static function updateTs(event:Event)
    {
        lastActivityTs = DateTime.nowUnixSecs();
    }
}
