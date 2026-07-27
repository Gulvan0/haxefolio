package haxefolio.overlay.builder;

import haxe.ui.Toolkit;
import haxe.ui.containers.SideBar;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.events.UIEvent;
import haxefolio.overlay.builder.components.OverlayCloseButton;
import js.Browser;

/*
    Mobile presentation: a SideBar sliding up from the bottom, sized to cover the entire viewport
    (including the menu bar) via `method = "float"`, which leaves the page container's own size
    untouched rather than shifting/resizing it. The page container and its current page are never
    touched here, so the page keeps running/redrawing underneath and is never destroyed; navigation
    state and the URL are untouched too.

    Deliberately exclusive, unlike ModalOverlay: a dedicated, full-screen `backdrop` is added to
    Screen.instance for the entire show->hidden window (opening, open, and closing), so nothing
    beneath the sidebar is reachable at any point during that window - not even the not-yet-covered
    sliver of screen mid-slide-animation. It carries no onClick dismiss handler; the only way to
    close this presentation is its close button or a content-driven `dismiss()` call. Do NOT set
    `sideBar.modal = true` - SideBar's own built-in overlay flag tears its own backdrop down the
    moment `hide()` is called, not once the slide-out animation actually finishes (`UIEvent.HIDDEN`,
    used below), which would reopen exactly the accidental-double-tap gap this backdrop exists to
    close.

    A fresh SideBar (and backdrop) is built on every call, so it is the caller's
    (HaxeFolioApp.showOverlay's) responsibility to not call this again before `onDismissed` fires
    for a previous call - HaxeUI's own SideBar tracks only one `activeSideBar` at a time, so two
    coexisting instances fighting over that single slot produces visibly broken show/hide
    animations.
*/
class SideBarOverlay
{
    public static function show(slug:String, content:OverlayContent, showCloseButton:Bool, ?closeButtonSize:Int, ?closeButtonInsetX:Int, ?closeButtonInsetY:Int, onDismissed:Void->Void):Void->Void
    {
        /*
            Sized from a direct, live DOM read rather than percentWidth/percentHeight or
            Screen.instance.width/height/actualWidth/actualHeight: all of those bottom out in
            ScreenImpl's own cached _width/_height, refreshed only by a native browser `resize`
            event (see ScreenImpl.containerResized) - which, per ResponsivityController's own
            comment, Chrome/Firefox's device-emulation toolbar doesn't reliably fire (confirmed:
            works via genuine window resize, breaks via the device toolbar). A stale cache here
            means percentWidth=100 resolves against whatever width was current before the toolbar
            was opened, not the actual (often much narrower) emulated one - the sidebar (and the
            close button positioned relative to it) then renders far outside the real viewport.
            `Browser.document.body.offsetWidth`/`offsetHeight` are always live; dividing by
            Toolkit.scaleX/scaleY converts them into the same pre-DPI-scale coordinate space
            `.width`/`.height` are otherwise expected to be in (see ScreenImpl.addComponent's
            `transform: scale(...)`), matching what Screen.instance.width/height compute when their
            cache isn't stale.
        */
        var viewportWidth:Float = Browser.document.body.offsetWidth / Toolkit.scaleX;
        var viewportHeight:Float = Browser.document.body.offsetHeight / Toolkit.scaleY;

        var sideBar:SideBar = new SideBar();
        sideBar.id = 'haxefolio-overlay-$slug-sidebar';
        sideBar.addClass("haxefolio-overlay-sidebar");
        sideBar.position = "bottom";
        sideBar.method = "float";
        sideBar.width = viewportWidth;
        sideBar.height = viewportHeight;

        var backdrop:Component = new Component();
        backdrop.id = 'haxefolio-overlay-$slug-backdrop';
        backdrop.addClass("haxefolio-overlay-backdrop");
        backdrop.width = viewportWidth;
        backdrop.height = viewportHeight;

        content.id = 'haxefolio-overlay-$slug-content';
        content.addClass("haxefolio-overlay-content");

        function dismiss():Void
        {
            content.dispose();
            sideBar.hide();
        }

        var closeButton:Null<OverlayCloseButton> = showCloseButton
            ? new OverlayCloseButton('haxefolio-overlay-$slug-close-button', dismiss, closeButtonSize)
            : null;

        /*
            No intermediate wrapper needed: content is expected to be percentWidth/percentHeight
            100, the same way the built-in preference window's content is, and the floated
            closeButton is positioned independently of normal box layout either way.
        */
        sideBar.addComponent(content);

        if (closeButton != null)
        {
            /*
                Floated (`includeInLayout = false`) rather than laid out as its own row - see
                OverlayLayout, which is what actually places it once real geometry is known.
            */
            closeButton.includeInLayout = false;

            /*
                Guards against any inherited margin offsetting the DOM position on top of the exact
                `left`/`top` OverlayLayout computes below.
            */
            closeButton.customStyle.marginLeft = 0;
            closeButton.customStyle.marginTop = 0;

            sideBar.addComponent(closeButton);
        }

        /*
            SideBar.hide() only animates + hides; since a fresh SideBar is built on every show()
            call, it must also be pruned from the screen once the hide animation completes, or
            repeated opens would keep piling up hidden SideBars. UIEvent.HIDDEN (confirmed via
            SideBar's own onHideAnimationEnd -> super.hide() chain, only reached from the CSS
            animation's onAnimationEnd) fires only once the slide-out has actually finished - which
            is also why backdrop removal is deliberately placed here rather than inside dismiss():
            removing it eagerly, the moment sideBar.hide() is called, would let input through to the
            page underneath while the panel is still visibly sliding away. This is also the single
            point at which the panel is fully gone, so it doubles as the `onDismissed` signal that
            lets the caller allow a new show() call again.
        */
        sideBar.registerEvent(UIEvent.HIDDEN, _ ->
        {
            Screen.instance.removeComponent(backdrop, true);
            Screen.instance.removeComponent(sideBar, true);
            onDismissed();
        });

        Screen.instance.addComponent(backdrop);
        sideBar.show();

        /*
            sideBar.show() adds sideBar to Screen.instance itself (it's a fresh instance every
            call, never added ahead of time) - only after that call returns is
            Screen.instance.rootComponents.indexOf(sideBar) guaranteed to resolve to a real index,
            which is why this runs after show() rather than before it. Placing backdrop directly
            beneath sideBar in z-order this way mirrors the technique SideBar's own internal
            showModalOverlay() uses for the same reason - without it, backdrop would render (and
            hit-test) on top of sideBar instead of beneath it, silently swallowing every click meant
            for the sidebar's own close button/content.

            The -1 adjustment matters: backdrop was already added (a few lines up, right before
            sideBar.show()) at whatever index came before sideBar's own self-add, so it already sits
            earlier in rootComponents than sideBar does. setComponentIndex removes it from that
            earlier slot before reinserting it - which shifts sideBar's own index down by one - so
            reinserting at sideBar's pre-removal index overshoots by one and lands backdrop *after*
            sideBar instead of directly before it.
        */
        var sideBarIndex:Int = Screen.instance.rootComponents.indexOf(sideBar);
        var backdropIndex:Int = Screen.instance.rootComponents.indexOf(backdrop);
        Screen.instance.setComponentIndex(backdrop, backdropIndex < sideBarIndex ? sideBarIndex - 1 : sideBarIndex);

        if (closeButton != null)
            OverlayLayout.attachCloseButtonPositioning(sideBar, content, closeButton, closeButtonInsetX, closeButtonInsetY);

        return dismiss;
    }
}
