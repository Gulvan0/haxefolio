package haxefolio.overlay;

import haxe.ui.core.Component;
import haxefolio.appearance.AppearanceContext;
import haxefolio.appearance.AppearanceOverrides;
import haxefolio.overlay.builder.DialogPresentation;
import haxefolio.overlay.builder.OverlayPresentation;
import haxefolio.overlay.builder.SheetPresentation;
import haxefolio.structure.RegionStack;
import js.Browser;
import js.html.KeyboardEvent;

/*
    The framework's single overlay at a time: builds the content, picks a presentation, and owns
    everything that is the same in both - the no-op while one is already open, Esc, and making the
    rest of the app unreachable. HaxeFolioApp.present/dismissing on navigation are thin wrappers
    over this.

    Making the rest of the app unreachable is done by marking its root components `inert`, rather
    than by a scrim's pointer-events: `inert` takes them out of hit-testing, the tab order and
    assistive technology at once - which is the scrim, focus trap and scroll lock of a modal in one
    attribute, and holds for the whole show -> gone window, sheet slide-out included. The frame and
    scrim are Screen root components of their own, so they are not affected.

    Presentation (dialog or sheet) is picked once, by ResponsivityController.isCollapsed at the
    moment of presenting, and fixed for that overlay's lifetime: swapping live would have to rebuild
    the content from the other factory and lose whatever the user had typed.
*/
class OverlayController
{
    private static var inertComponents:Array<Component> = [];
    private static var isOpen:Bool = false;
    private static var presentation:Null<OverlayPresentation> = null;
    private static var requestDismissal:Null<Void->Void> = null;

    /*
        Registers the app's own root components, which are marked inert while an overlay is open.
        Called once by HaxeFolioApp.init.
    */
    public static function init(inertComponents:Array<Component>):Void
    {
        OverlayController.inertComponents = inertComponents;
    }

    public static function present(slug:String, contentFactory:(Void->Void)->OverlayContent, ?mobileContentFactory:(Void->Void)->OverlayContent, ?appearance:AppearanceOverrides, ?onDismissed:Void->Void):Void
    {
        if (isOpen)
            return;

        isOpen = true;

        var isCollapsed:Bool = ResponsivityController.isCollapsed;
        var factory:(Void->Void)->OverlayContent = (isCollapsed && mobileContentFactory != null) ? mobileContentFactory : contentFactory;

        var isClosing:Bool = false;

        function dismiss():Void
        {
            if (isClosing || presentation == null)
                return;

            isClosing = true;
            presentation.hide();
        }

        function onKeyDown(event:KeyboardEvent):Void
        {
            if (event.key != "Escape")
                return;

            event.preventDefault();
            event.stopPropagation();
            dismiss();
        }

        var content:Null<OverlayContent> = null;
        var stack:RegionStack;

        // built under the overlay's own appearance, so every component reads it (see AppearanceContext)
        try
        {
            stack = AppearanceContext.runWith(appearance, () -> {
                content = factory(dismiss);
                return new RegionStack(content.regions, 0);
            });
        }
        catch (e:Dynamic)
        {
            isOpen = false;

            if (content != null && content.onDismissed != null)
                content.onDismissed();

            throw e;
        }

        function onGone():Void
        {
            stack.dispose();

            for (component in inertComponents)
                component.element.removeAttribute("inert");

            Browser.document.removeEventListener("keydown", onKeyDown, true);

            isOpen = false;
            presentation = null;
            requestDismissal = null;

            if (content.onDismissed != null)
                content.onDismissed();

            if (onDismissed != null)
                onDismissed();
        }

        var styleClass:Null<String> = appearance?.styleClass;

        presentation = isCollapsed
            ? new SheetPresentation(slug, stack, styleClass, onGone)
            : new DialogPresentation(slug, stack, styleClass, onGone);
        requestDismissal = dismiss;

        for (component in inertComponents)
            component.element.setAttribute("inert", "");

        // capture phase, so Esc reaches this before anything inside the overlay can swallow it
        Browser.document.addEventListener("keydown", onKeyDown, true);

        presentation.show();
    }

    /*
        Closes the open overlay, if any - used when the page changes underneath it. Safe to call
        while one is already closing.
    */
    public static function dismissIfOpen():Void
    {
        if (requestDismissal != null)
            requestDismissal();
    }

    /*
        Re-fits the open overlay's frame to the viewport, if any. Called off the same debounced
        resize signal ResponsivityController already computes.
    */
    public static function resize():Void
    {
        if (presentation != null)
            presentation.resize();
    }
}
