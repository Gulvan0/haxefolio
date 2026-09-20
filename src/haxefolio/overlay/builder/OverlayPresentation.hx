package haxefolio.overlay.builder;

import haxe.ui.Toolkit;
import haxefolio.structure.RegionStack;
import js.Browser;
import js.html.Element;

/*
    One way of putting an overlay's region stack on screen: a stable frame around it, a scrim
    behind it, and a way out. The two implementations (DialogPresentation, SheetPresentation) are
    private to the framework - a host never names one, see HaxeFolioApp.present.

    A presentation only ever sets the stack's `frameHeight`; the stack owns the regions and their
    heights. Dismissal triggers (Esc, a `dismiss` call, navigation) are not its business either:
    OverlayController calls `hide()`, and the presentation reports back through `onGone` once
    nothing of it is left on screen - which for an animated presentation is later than `hide()`.
*/
class OverlayPresentation
{
    private final slug:String;
    private final stack:RegionStack;
    private final styleClass:Null<String>;
    private final onGone:Void->Void;

    private function new(slug:String, stack:RegionStack, styleClass:Null<String>, onGone:Void->Void)
    {
        this.slug = slug;
        this.stack = stack;
        this.styleClass = styleClass;
        this.onGone = onGone;
    }

    /**
        Puts the overlay on screen.
    **/
    public function show():Void
    {
        throw "abstract";
    }

    /**
        Starts taking the overlay off screen; calls `onGone` once it is entirely gone.
    **/
    public function hide():Void
    {
        throw "abstract";
    }

    /**
        Re-fits the frame to the viewport. Called off the debounced viewport resize signal.
    **/
    public function resize():Void
    {
        throw "abstract";
    }

    /*
        Clipping (so a region's square corners never poke past the frame's rounded ones) and the
        elevation shadow are set on the DOM element directly: HaxeUI's `clip` and `filter` style
        properties did not take effect on the frame from the stylesheet.
    */
    private static function styleFrameElement(element:Element, shadow:String):Void
    {
        element.style.overflow = "hidden";
        element.style.boxShadow = shadow;
    }

    /*
        Sized from a direct, live DOM read rather than Screen.instance.width/height: those bottom
        out in ScreenImpl's cached size, refreshed only by a native browser `resize` event, which
        Chrome/Firefox's device-emulation toolbar doesn't reliably fire (see ResponsivityController).
        A stale cache would size the overlay for whatever the viewport was before the toolbar was
        opened. Dividing by Toolkit.scaleX/scaleY converts the DOM measurement into the same
        coordinate space `.width`/`.height` are expected to be in (ScreenImpl.addComponent applies
        `transform: scale(...)`).
    */
    private static function viewportWidth():Float
    {
        return Browser.document.body.offsetWidth / Toolkit.scaleX;
    }

    private static function viewportHeight():Float
    {
        return Browser.document.body.offsetHeight / Toolkit.scaleY;
    }
}
