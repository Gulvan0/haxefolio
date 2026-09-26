package haxefolio;

import haxe.ui.core.Component;
import js.Browser;
import morestd.Detachable;
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

    The observed element is document.body, the viewport itself: the collapse threshold is a
    property of the viewport, not of any one component laid out in it.
*/
class ResponsivityController
{
    /*
        Whether the menu bar is currently in its collapsed (mobile) state - exposed so other parts
        of the framework (e.g. HaxeFolioApp.showPreferences) can pick a presentation appropriate to
        the current layout mode without duplicating the menuCollapseWidth comparison.
    */
    public static var isCollapsed(default, null):Bool = false;

    private static var collapseChangeListeners:Array<Bool->Void> = [];

    private static var pageContainer:Component;
    private static var hamburgerButton:Component;
    private static var collapsibleMenuBarComponents:Array<Component>;
    private static var menuCollapseWidth:Int;
    private static var onDebouncedResize:Float->Float->Void;
    private static var debounceTimer:RefreshableTimer;
    private static var latestWidth:Float;
    private static var hasAppliedInitialState:Bool;

    public static function init(pageContainer:Component, hamburgerButton:Component, collapsibleMenuBarComponents:Array<Component>, menuCollapseWidth:Int, debounceMs:Int, onDebouncedResize:Float->Float->Void):Void
    {
        ResponsivityController.pageContainer = pageContainer;
        ResponsivityController.hamburgerButton = hamburgerButton;
        ResponsivityController.collapsibleMenuBarComponents = collapsibleMenuBarComponents;
        ResponsivityController.menuCollapseWidth = menuCollapseWidth;
        ResponsivityController.onDebouncedResize = onDebouncedResize;
        ResponsivityController.hasAppliedInitialState = false;

        debounceTimer = new RefreshableTimer(debounceMs, applyResize);

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
        var newCollapsed:Bool = latestWidth < menuCollapseWidth;
        var changed:Bool = newCollapsed != isCollapsed;

        isCollapsed = newCollapsed;

        for (component in collapsibleMenuBarComponents)
            component.hidden = isCollapsed;

        hamburgerButton.hidden = !isCollapsed;

        if (changed)
            for (listener in collapseChangeListeners)
                listener(isCollapsed);
    }

    /**
        The framework's only breakpoint subscription: applies `value` for the current state
        immediately, then re-applies it whenever `isCollapsed` actually flips (not on every debounced
        resize) - so a component built after the initial layout still starts in sync rather than
        assuming the collapsed default. Anything whose layout depends on the breakpoint beyond what
        the menu bar itself already reacts to takes a `ByWidth` and passes it through here.

        Detach the returned handle once the subscriber is disposed. For a `ByWidth` that is the same
        in both states, `apply` runs once and nothing is subscribed, so the handle is a harmless no-op.
    **/
    public static function bind<T>(value:ByWidth<T>, apply:T->Void):Detachable
    {
        if (value.isConstant)
        {
            apply(value.resolve(isCollapsed));
            return new Detachable(() -> {});
        }

        return onCollapseChange(collapsed -> apply(value.resolve(collapsed)));
    }

    /*
        Notifies `listener` whenever `isCollapsed` actually flips, immediately with the current value first.
    */
    @:allow(haxefolio)
    private static function onCollapseChange(listener:Bool->Void):Detachable
    {
        collapseChangeListeners.push(listener);
        listener(isCollapsed);

        return new Detachable(() -> collapseChangeListeners.remove(listener), false);
    }
}
