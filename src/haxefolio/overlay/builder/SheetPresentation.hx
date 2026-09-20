package haxefolio.overlay.builder;

import haxe.ui.containers.SideBar;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.events.UIEvent;
import haxefolio.structure.RegionStack;

/*
    Collapsed presentation: a SideBar sliding up from the bottom, covering the entire viewport
    (menu bar included). `method = "float"` leaves the page container's own size untouched
    rather than shifting/resizing it, so the page keeps running underneath and is never destroyed;
    navigation state and the URL are untouched too.

    Fully exclusive: a dedicated, full-screen `scrim` is added to Screen.instance for the entire
    show -> hidden window (opening, open and closing), so nothing beneath the sheet is reachable at
    any point during it - not even the not-yet-covered sliver of screen mid-slide-animation. It
    carries no dismiss handler. (The sheet itself covers the whole viewport once open, so the scrim
    is only ever visible mid-animation.) Do NOT set `sideBar.modal = true`: SideBar's own built-in overlay
    flag tears its backdrop down the moment `hide()` is called, not once the slide-out animation
    actually finishes (`UIEvent.HIDDEN`, used below), which would reopen exactly the
    accidental-double-tap gap this scrim exists to close.

    A fresh SideBar is built per overlay; HaxeUI's own SideBar tracks only one `activeSideBar` at
    a time, so two coexisting instances would fight over that slot and break the show/hide
    animations - OverlayController guarantees only one overlay exists at a time.
*/
class SheetPresentation extends OverlayPresentation
{
    private final scrim:Component;
    private final sideBar:SideBar;

    public function new(slug:String, stack:RegionStack, styleClass:Null<String>, onGone:Void->Void)
    {
        super(slug, stack, styleClass, onGone);

        scrim = new Component();
        scrim.id = 'haxefolio-overlay-$slug-scrim';
        scrim.addClass("haxefolio-overlay-scrim");
        scrim.addClass("haxefolio-overlay-sheet-scrim");

        sideBar = new SideBar();
        sideBar.id = 'haxefolio-overlay-$slug-frame';
        sideBar.addClass("haxefolio-overlay-frame");
        sideBar.addClass("haxefolio-overlay-sheet");
        sideBar.position = "bottom";
        sideBar.method = "float";

        // on the frame only: a variant's own colours must not paint over the scrim
        if (styleClass != null)
            sideBar.addClass(styleClass);

        sideBar.addComponent(stack);

        /*
            SideBar.hide() only animates + hides; a fresh SideBar is built per overlay, so it must
            also be pruned from the screen once the hide animation completes. UIEvent.HIDDEN fires
            only once the slide-out has actually finished - which is also why the scrim is removed
            here rather than in hide(): removing it eagerly would let input through to the page
            while the sheet is still visibly sliding away. It is also the one point at which the
            sheet is fully gone.
        */
        sideBar.registerEvent(UIEvent.HIDDEN, _ -> {
            Screen.instance.removeComponent(scrim, true);
            Screen.instance.removeComponent(sideBar, true);
            onGone();
        });

        applySize();
    }

    public override function show():Void
    {
        Screen.instance.addComponent(scrim);
        sideBar.show();

        OverlayPresentation.styleFrameElement(sideBar.element, "0 -4px 20px rgba(24, 26, 31, 0.18)");

        /*
            sideBar.show() adds sideBar to Screen.instance itself, so only after it returns does
            rootComponents.indexOf(sideBar) resolve to a real index. The scrim must sit directly
            beneath the sheet in z-order, or it would render (and hit-test) on top of it and
            swallow every click meant for the sheet - the same technique SideBar's own
            showModalOverlay() uses. The -1 accounts for the scrim already sitting earlier in
            rootComponents: setComponentIndex removes it from that slot first, which shifts the
            sheet's own index down by one.
        */
        var sideBarIndex:Int = Screen.instance.rootComponents.indexOf(sideBar);
        var scrimIndex:Int = Screen.instance.rootComponents.indexOf(scrim);
        Screen.instance.setComponentIndex(scrim, scrimIndex < sideBarIndex ? sideBarIndex - 1 : sideBarIndex);
    }

    public override function hide():Void
    {
        sideBar.hide();
    }

    public override function resize():Void
    {
        applySize();
    }

    private function applySize():Void
    {
        var width:Float = OverlayPresentation.viewportWidth();
        var height:Float = OverlayPresentation.viewportHeight();

        scrim.width = width;
        scrim.height = height;

        sideBar.width = width;
        stack.frameHeight = height;
        sideBar.height = height;
    }
}
