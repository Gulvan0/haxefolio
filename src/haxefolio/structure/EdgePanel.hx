package haxefolio.structure;

import haxe.Timer;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxe.ui.core.Screen;
import haxefolio.Viewport;
import js.html.Element;
import js.html.Event;

/**
    A panel sliding in from an edge of the viewport over a scrim covering the whole viewport - the
    building block of the menu side bar and of the collapsed overlay presentation (the sheet).

    The owner sizes the panel (its `width`/`height`), adds its content, and calls `fit()` whenever
    the viewport changes; the panel positions itself against its edge and sizes the scrim. `open()`
    puts both on screen and slides the panel in while the scrim fades in; `close()` reverses that,
    and calls `onGone` once both are off screen. The scrim stays for as long as the panel is on
    screen, closing included, so nothing beneath it is reachable at any point of the slide.

    `scrim` is exposed for the owner to give it an id and classes; its colour comes from the
    stylesheet. Clicking it calls `onScrimClick`, if given - otherwise it only blocks input.
**/
class EdgePanel extends VBox
{
    private static inline final SLIDE_DURATION_MS:Int = 260;
    private static inline final FADE_DURATION_MS:Int = 220;
    private static inline final EASING:String = "cubic-bezier(.2, .8, .2, 1)";

    // a margin for the backup timer standing in for a `transitionend` that never arrives
    private static inline final GONE_BACKUP_MARGIN_MS:Int = 100;

    /**
        The scrim behind the panel. On screen exactly while the panel is.
    **/
    public final scrim:Box;

    /**
        Whether the panel is on screen: opening, open or closing.
    **/
    public var isOnScreen(default, null):Bool = false;

    /**
        Whether the panel is on screen but sliding out.
    **/
    public var isClosing(default, null):Bool = false;

    private final edge:EdgePanelEdge;
    private final onGone:Void->Void;
    private final disposeOnGone:Bool;
    private var goneBackupTimer:Null<Timer> = null;

    /**
        `onGone` runs every time the panel has entirely left the screen. With `disposeOnGone`, the
        panel and the scrim are also disposed then - for a panel built per use; without it, the
        panel may be shown again.
    **/
    public function new(edge:EdgePanelEdge, onGone:Void->Void, ?onScrimClick:Void->Void, disposeOnGone:Bool = false)
    {
        super();

        this.edge = edge;
        this.onGone = onGone;
        this.disposeOnGone = disposeOnGone;

        scrim = new Box();

        if (onScrimClick != null)
            scrim.onClick = _ -> onScrimClick();
    }

    /**
        Puts the panel on screen and slides it in. Called while the panel is closing, it slides
        back in from wherever it is; while it is already open, it does nothing.
    **/
    public function open():Void
    {
        if (isOnScreen && !isClosing)
            return;

        if (isClosing)
        {
            cancelGone();
            isClosing = false;
            applyState(true, true);
            return;
        }

        isOnScreen = true;
        fit();
        Screen.instance.addComponent(scrim);
        Screen.instance.addComponent(this);

        // start from the closed position without a transition, so the slide has somewhere to come from
        applyState(false, false);
        forceStyleFlush();
        applyState(true, true);
    }

    /**
        Slides the panel out and calls `onGone` once it is off screen; with `animated == false`, it
        is taken off screen at once. Does nothing while the panel is not on screen, and nothing
        more while it is already closing, except that a closing panel can still be finished at
        once with `animated == false`.
    **/
    public function close(animated:Bool = true):Void
    {
        if (!isOnScreen)
            return;

        if (!animated)
        {
            finishGone();
            return;
        }

        if (isClosing)
            return;

        isClosing = true;
        applyState(false, true);
        this.element.addEventListener("transitionend", onTransitionEnd);
        goneBackupTimer = Timer.delay(finishGone, SLIDE_DURATION_MS + GONE_BACKUP_MARGIN_MS);
    }

    /**
        Sizes the scrim to the viewport and positions the panel against its edge, for the panel's
        current size. Call it after changing the panel's size or whenever the viewport changes.
    **/
    public function fit():Void
    {
        var viewportWidth:Float = Viewport.width();
        var viewportHeight:Float = Viewport.height();

        scrim.width = viewportWidth;
        scrim.height = viewportHeight;

        this.left = 0;
        this.top = switch edge {
            case Left: 0;
            case Bottom: viewportHeight - (this.height ?? viewportHeight);
        }
    }

    /*
        The slide is the CSS `translate` property rather than `transform`: HaxeUI puts its own
        `transform: scale(...)` on every root component when the toolkit is scaled, and the two
        compose instead of one overwriting the other. Both are set on the DOM elements directly -
        HaxeUI's own animations only know named easings.
    */
    private function applyState(open:Bool, animated:Bool):Void
    {
        var panelElement:Element = this.element;
        panelElement.style.setProperty("transition", animated ? 'translate ${SLIDE_DURATION_MS}ms $EASING' : "none");
        panelElement.style.setProperty("translate", open ? "0 0" : closedTranslate());

        var scrimElement:Element = scrim.element;
        scrimElement.style.setProperty("transition", animated ? 'opacity ${FADE_DURATION_MS}ms $EASING' : "none");
        scrimElement.style.setProperty("opacity", open ? "1" : "0");
    }

    private function closedTranslate():String
    {
        return switch edge {
            case Left: "-100% 0";
            case Bottom: "0 100%";
        }
    }

    // reading a layout property makes the browser apply the pending styles, so the next change transitions from them
    private function forceStyleFlush():Void
    {
        var _:Int = this.element.offsetWidth + scrim.element.offsetWidth;
    }

    // `transitionend` bubbles up from the panel's content too, so only the panel's own slide counts
    private function onTransitionEnd(event:Event):Void
    {
        if (event.target == this.element && (cast event : Dynamic).propertyName == "translate")
            finishGone();
    }

    private function finishGone():Void
    {
        cancelGone();

        isOnScreen = false;
        isClosing = false;

        Screen.instance.removeComponent(this, disposeOnGone);
        Screen.instance.removeComponent(scrim, disposeOnGone);

        onGone();
    }

    private function cancelGone():Void
    {
        this.element.removeEventListener("transitionend", onTransitionEnd);

        if (goneBackupTimer != null)
        {
            goneBackupTimer.stop();
            goneBackupTimer = null;
        }
    }
}
