package haxefolio;

import haxe.ui.Toolkit;
import js.Browser;

/*
    The viewport's live size, in the coordinate space HaxeUI components' `width`/`height` use.

    Read directly from the DOM rather than from Screen.instance.width/height: those bottom out in
    ScreenImpl's cached size, refreshed only by a native browser `resize` event, which
    Chrome/Firefox's device-emulation toolbar doesn't reliably fire (see ResponsivityController).
    A stale cache would size whatever reads it for the viewport as it was before the toolbar was
    opened. Dividing by Toolkit.scaleX/scaleY converts the DOM measurement into the coordinate space
    `.width`/`.height` are expected to be in (ScreenImpl.addComponent applies `transform: scale(...)`).
*/
class Viewport
{
    @:allow(haxefolio)
    private static function width():Float
    {
        return Browser.document.body.offsetWidth / Toolkit.scaleX;
    }

    @:allow(haxefolio)
    private static function height():Float
    {
        return Browser.document.body.offsetHeight / Toolkit.scaleY;
    }
}
