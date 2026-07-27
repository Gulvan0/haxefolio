package haxefolio;

import haxe.ui.containers.Box;
import js.Browser;
import haxefolio.browser.Blinker;

@:allow(haxefolio.HaxeFolioApp)
class PageBase extends Box
{
    private var titleWasSet:Bool = false;
    private var activeBlink:Null<Blinker>;

    private var titleText:String;
    private var titleParam0:Any;
    private var titleParam1:Any;
    private var titleParam2:Any;
    private var titleParam3:Any;

    private var blinkText:String;
    private var blinkParam0:Any;
    private var blinkParam1:Any;
    private var blinkParam2:Any;
    private var blinkParam3:Any;
    private var blinkIconHref:Null<String>;
    private var blinkIntervalMs:Int;

    private function new()
    {
        super();

        this.percentWidth = 100;
        this.percentHeight = 100;
        this.padding = 5;
    }

    /**
        Called by the framework after the page is added to the container. A framework user may
        override this to perform initialization logic. May throw - the framework catches the
        exception and redirects to the default page. It is possible to call
        `HaxeFolioApp.navigateTo` from here to redirect to another page before this one is opened
        (in case something happens during initialization).
    **/
    private function init():Void
    {
    }

    /**
        Called by the framework when the container is resized, after the debounce period. A
        framework user may override this to respond to size changes. `width` and `height` are the
        new dimensions of the page container in pixels.
    **/
    private function onResize(width:Float, height:Float):Void
    {
    }

    /**
        Called by the framework before the page is destroyed and the user is navigated away.
        Override to perform cleanup (e.g. detaching preference hooks, cancelling pending
        requests). It is forbidden to call `HaxeFolioApp.navigateTo` from here.
    **/
    private function onClose():Void
    {
    }

    /**
        Assigns `document.title` to `LocaleUtils.resolveText(text, param0, param1, param2, param3)` -
        see `LocaleUtils.resolveText` for exactly how `text`/`param0`-`param3` are interpreted. Callable
        from `init` or at any later point (e.g. once data that only becomes available
        asynchronously has arrived). Stops any active blink for this page first.
    **/
    private function setTitle(text:String, ?param0:Any, ?param1:Any, ?param2:Any, ?param3:Any):Void
    {
        stopBlink();

        titleText = text;
        titleParam0 = param0;
        titleParam1 = param1;
        titleParam2 = param2;
        titleParam3 = param3;

        Browser.document.title = LocaleUtils.resolveText(text, param0, param1, param2, param3);
        titleWasSet = true;
    }

    /**
        Starts alternating the tab title between its current value and
        `LocaleUtils.resolveText(text, param0, param1, param2, param3)` (see `LocaleUtils.resolveText`), once
        every `intervalMs` (1000 by default). If `iconHref` is given, the favicon is swapped in
        lockstep with the title - notification icon while showing the notification text, restored
        to whatever it was before while showing the normal title; if omitted, only the title
        blinks. Can only be called after `setTitle` (throws otherwise, since there'd be no "normal"
        title/favicon yet to restore to). Replaces any already-active blink for this page rather
        than stacking (there is only one `document.title`/favicon, so only one blink can be
        meaningfully active at a time).
    **/
    private function startBlink(text:String, ?param0:Any, ?param1:Any, ?param2:Any, ?param3:Any, ?iconHref:String, intervalMs:Int = Blinker.DEFAULT_INTERVAL):Void
    {
        if (!titleWasSet)
            throw "startBlink can only be called after setTitle.";

        blinkText = text;
        blinkParam0 = param0;
        blinkParam1 = param1;
        blinkParam2 = param2;
        blinkParam3 = param3;
        blinkIconHref = iconHref;
        blinkIntervalMs = intervalMs;

        var notificationText:String = LocaleUtils.resolveText(text, param0, param1, param2, param3);

        stopBlink();
        activeBlink = new Blinker(notificationText, iconHref, intervalMs);
        activeBlink.start();
    }

    /**
        Stops this page's active blink, if any, restoring the title/favicon it had before the
        blink started. A no-op if no blink is active.
    **/
    private function stopBlink():Void
    {
        if (activeBlink == null)
            return;

        activeBlink.stop();
        activeBlink = null;
    }

    /*
        Called by HaxeFolioApp whenever the language preference changes, so this page's tab
        title/blink text stays in sync with the newly selected language - unlike {{key}}-bound
        component text, setTitle/startBlink resolve their string once and don't otherwise refresh.
        A no-op for a page whose title/blink text was set to a literal (not a {{key}} binding),
        since there's nothing for it to resync to.
    */
    private function resyncLocalizedText():Void
    {
        if (!titleWasSet)
            return;

        var resolvedTitle:String = LocaleUtils.resolveText(titleText, titleParam0, titleParam1, titleParam2, titleParam3);
        var blinkWasActive:Bool = activeBlink != null;
        var resolvedNotification:String = blinkWasActive
            ? LocaleUtils.resolveText(blinkText, blinkParam0, blinkParam1, blinkParam2, blinkParam3)
            : null;

        stopBlink();
        Browser.document.title = resolvedTitle;

        if (blinkWasActive)
        {
            activeBlink = new Blinker(resolvedNotification, blinkIconHref, blinkIntervalMs);
            activeBlink.start();
        }
    }

    private function finalizeClose():Void
    {
        onClose();
        stopBlink();
    }
}
