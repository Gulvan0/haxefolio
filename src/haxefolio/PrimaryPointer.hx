package haxefolio;

import js.Browser;
import js.html.MediaQueryList;
import js.html.MediaQueryListEvent;
import morestd.Detachable;

/**
    What kind of pointer the device's primary input is - the counterpart of the width breakpoint
    (`ResponsivityController`) for input rather than layout: a coarse pointer (a finger) has no
    hover, no right button and no modifier keys, whatever the screen's size. Follows the
    `(pointer: coarse)` media query, which changes e.g. when a tablet's keyboard cover is attached
    or devtools start emulating touch.
**/
class PrimaryPointer
{
    private static var query:Null<MediaQueryList> = null;

    /**
        Whether the primary pointer is coarse right now.
    **/
    public static function isCoarse():Bool
    {
        return mediaQuery().matches;
    }

    /**
        Calls `apply` with `isCoarse()` immediately, then again whenever it changes, until the
        returned handle is detached.
    **/
    public static function bind(apply:Bool->Void):Detachable
    {
        var listener:MediaQueryListEvent->Void = _ -> apply(isCoarse());
        mediaQuery().addEventListener("change", listener);
        apply(isCoarse());

        return new Detachable(() -> {
            mediaQuery().removeEventListener("change", listener);
        }, false);
    }

    private static function mediaQuery():MediaQueryList
    {
        if (query == null)
            query = Browser.window.matchMedia("(pointer: coarse)");
        return query;
    }
}
