package haxefolio.browser;

import morestd.DateTime;
import js.html.Event;
import js.Browser;

class ActivityTracker
{
    private static var lastActivityTs:Int;
    private static var isActive:Bool = false;
    private static var idleThresholdSecs:Int = 0;
    private static var onResumeAfterIdle:Null<Void->Void> = null;

    /**
        `onResumeAfterIdle` is called when the user interacts with the page after not having done so
        for at least `idleThresholdSecs`.
    **/
    public static function activate(?idleThresholdSecs:Int = 0, ?onResumeAfterIdle:Void->Void)
    {
        if (isActive)
            return;

        isActive = true;
        ActivityTracker.idleThresholdSecs = idleThresholdSecs;
        ActivityTracker.onResumeAfterIdle = onResumeAfterIdle;
        for (eventKind in ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart'])
            Browser.document.addEventListener(eventKind, updateTs);
    }

    public static function getLastActivityTs():Int
    {
        return lastActivityTs;
    }

    private static function updateTs(event:Event)
    {
        var now:Int = DateTime.nowUnixSecs();
        var wasIdle:Bool = onResumeAfterIdle != null && lastActivityTs > 0 && now - lastActivityTs >= idleThresholdSecs;
        lastActivityTs = now;
        if (wasIdle)
            onResumeAfterIdle();
    }
}
