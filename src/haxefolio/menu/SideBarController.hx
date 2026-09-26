package haxefolio.menu;

import haxe.ui.core.Component;
import haxefolio.ElementShadow;
import haxefolio.InertHolds;
import haxefolio.ResponsivityController;
import haxefolio.Viewport;
import haxefolio.overlay.OverlayController;
import haxefolio.structure.EdgePanel;
import js.Browser;
import js.html.KeyboardEvent;
import morestd.Detachable;

/*
    Opens and closes the menu side bar, and owns what applies while it is on screen: the rest of the
    app is inert (through InertHolds, shared with overlays), Esc closes it, and so do navigation, a
    click on its scrim, and the menu bar leaving its collapsed layout - that last one at once, since
    the side bar has nothing left to stand in for.

    It is not an overlay: it does not take OverlayController's one-at-a-time slot, so an overlay
    may be presented while it is open or closing, over it. While one is, Esc belongs to the overlay.
*/
class SideBarController
{
    private static inline final PREFERRED_WIDTH:Int = 320;

    // the part of the viewport the scrim keeps uncovered at the least, so there is always somewhere to tap it
    private static inline final MINIMUM_SCRIM_WIDTH:Int = 56;

    private static var panel:EdgePanel;
    private static var inertComponents:Array<Component>;
    private static var inertHold:Null<Detachable> = null;

    /*
        `panel` must have been built with `handleGone` as its `onGone` and `close` as its
        `onScrimClick`; `inertComponents` are the app's own root components.
    */
    @:allow(haxefolio)
    private static function init(panel:EdgePanel, inertComponents:Array<Component>):Void
    {
        SideBarController.panel = panel;
        SideBarController.inertComponents = inertComponents;

        ElementShadow.apply(panel.element, "4px 0 20px rgba(24, 26, 31, 0.18)");

        ResponsivityController.onCollapseChange(collapsed -> {
            if (!collapsed)
                close(false);
        });
    }

    @:allow(haxefolio)
    private static function open():Void
    {
        if (panel.isOnScreen && !panel.isClosing)
            return;

        if (inertHold == null)
        {
            inertHold = InertHolds.hold(inertComponents);
            // capture phase, as for overlays; an overlay presented later registers after this one, see onKeyDown
            Browser.document.addEventListener("keydown", onKeyDown, true);
        }

        fit();
        panel.open();
    }

    /*
        Starts closing the side bar, or - with `animated == false` - takes it off screen at once.
        Does nothing while it is not on screen.
    */
    @:allow(haxefolio)
    private static function close(animated:Bool = true):Void
    {
        panel.close(animated);
    }

    @:allow(haxefolio)
    private static function fit():Void
    {
        panel.width = Math.min(PREFERRED_WIDTH, Viewport.width() - MINIMUM_SCRIM_WIDTH);
        panel.height = Viewport.height();
        panel.fit();
    }

    @:allow(haxefolio)
    private static function handleGone():Void
    {
        Browser.document.removeEventListener("keydown", onKeyDown, true);
        inertHold.detach();
        inertHold = null;
    }

    /*
        Runs before an overlay's own Esc handler (both are capture-phase listeners on the document,
        and this one was registered first), so it steps aside while an overlay is open rather than
        relying on the overlay to stop it.
    */
    private static function onKeyDown(event:KeyboardEvent):Void
    {
        if (event.key != "Escape" || OverlayController.isOpen)
            return;

        event.preventDefault();
        close();
    }
}
