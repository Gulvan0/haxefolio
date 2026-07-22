package haxefolio;

import haxe.ui.core.Component;
import js.Browser;
import morestd.RefreshableTimer;

/*
    Reacts to viewport resizes: debounces them, then applies the menuCollapseWidth threshold to the
    menu bar and notifies the active page with the page container's current pixel dimensions.

    Deliberately bypasses haxeui's own Screen/UIEvent.RESIZE machinery, which bottoms out in a
    plain `window` "resize" listener (see ScreenImpl.addResizeListener) - that listener isn't
    reliably fired by every viewport change a browser's device-emulation tools make (confirmed with
    Chrome's Device Toolbar), which leaves Screen.instance.width stuck at whatever it was cached as
    before, indefinitely. A native ResizeObserver instead reports an element's live, current size
    regardless of what caused it to change.

    The observed element is document.body, not the page container itself: SideBar.show() clears
    percentWidth/percentHeight on every non-sidebar root component to freeze its pixel size for the
    open/close animation - regardless of `method`, even "float" - and only restores it on hide().
    Observing the page container directly would mean menu-collapse decisions go stale for as long
    as the sidebar stays open; document.body's own size is unaffected by that freeze.
*/
class ResponsivityController
{
    private static inline var DEBOUNCE_MS:Int = 500;

    /*
        Whether the menu bar is currently in its collapsed (mobile) state - exposed so other parts
        of the framework (e.g. HaxeFolioApp.showPreferences) can pick a presentation appropriate to
        the current layout mode without duplicating the menuCollapseWidth comparison.
    */
    public static var isCollapsed(default, null):Bool = false;

    private static var pageContainer:Component;
    private static var hamburgerButton:Component;
    private static var collapsibleMenuBarComponents:Array<Component>;
    private static var menuCollapseWidth:Int;
    private static var onDebouncedResize:Float->Float->Void;
    private static var debounceTimer:RefreshableTimer;
    private static var latestWidth:Float;
    private static var hasAppliedInitialState:Bool;

    public static function init(pageContainer:Component, hamburgerButton:Component, collapsibleMenuBarComponents:Array<Component>, menuCollapseWidth:Int, onDebouncedResize:Float->Float->Void):Void
    {
        ResponsivityController.pageContainer = pageContainer;
        ResponsivityController.hamburgerButton = hamburgerButton;
        ResponsivityController.collapsibleMenuBarComponents = collapsibleMenuBarComponents;
        ResponsivityController.menuCollapseWidth = menuCollapseWidth;
        ResponsivityController.onDebouncedResize = onDebouncedResize;
        ResponsivityController.hasAppliedInitialState = false;

        debounceTimer = new RefreshableTimer(DEBOUNCE_MS, applyResize);

        /*
            No synchronous initial read here - haxeui defers actual layout validation, so even a
            direct DOM measurement can still read as 0 immediately after addComponent. ResizeObserver
            is guaranteed to fire once, promptly, as soon as observe() is called, reporting the
            element's real current size - onElementResized treats that first callback as the
            (undebounced) initial application, and every later one as an actual resize.
        */
        var observer:Dynamic = js.Syntax.code("new ResizeObserver({0})", onElementResized);
        observer.observe(Browser.document.body);
    }

    private static function onElementResized(entries:Array<Dynamic>):Void
    {
        var contentRect:Dynamic = entries[0].contentRect;
        latestWidth = contentRect.width;

        if (!hasAppliedInitialState)
        {
            hasAppliedInitialState = true;
            applyMenuCollapseState();
        }
        else
            debounceTimer.start();
    }

    private static function applyResize():Void
    {
        debounceTimer.stop();

        applyMenuCollapseState();
        onDebouncedResize(pageContainer.element.offsetWidth, pageContainer.element.offsetHeight);
    }

    private static function applyMenuCollapseState():Void
    {
        isCollapsed = latestWidth < menuCollapseWidth;

        for (component in collapsibleMenuBarComponents)
            component.hidden = isCollapsed;

        hamburgerButton.hidden = !isCollapsed;
    }
}
