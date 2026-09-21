package haxefolio.overlay;

import haxe.ui.containers.VBox;
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
                return new RegionStack(content.regions, 0, dismiss, 'haxefolio-overlay-$slug');
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
        Builds the content under the given appearance and mounts its region stack in a bordered
        frame inside `into`. None of present's machinery applies: no scrim, no inert, no Esc, and it
        neither counts as the one open overlay nor blocks one - the host owns the frame's height
        and its teardown (the returned handle) instead.
    */
    public static function embed(slug:String, contentFactory:Void->OverlayContent, into:Component, frameHeight:Float, ?appearance:AppearanceOverrides):EmbeddedOverlay
    {
        var content:Null<OverlayContent> = null;
        var stack:RegionStack;

        try
        {
            stack = AppearanceContext.runWith(appearance, () -> {
                content = contentFactory();
                return new RegionStack(content.regions, frameHeight, null, 'haxefolio-overlay-$slug');
            });
        }
        catch (e:Dynamic)
        {
            if (content != null && content.onDismissed != null)
                content.onDismissed();

            throw e;
        }

        var frame:VBox = new VBox();
        frame.id = 'haxefolio-overlay-$slug-frame';
        frame.addClass("haxefolio-overlay-frame");
        frame.addClass("haxefolio-overlay-embedded");
        frame.percentWidth = 100;
        frame.height = frameHeight;

        // on the frame only, as for a presented overlay
        var styleClass:Null<String> = appearance?.styleClass;
        if (styleClass != null)
            frame.addClass(styleClass);

        frame.addComponent(stack);
        into.addComponent(frame);

        // clipping keeps a region's square corners inside the frame's rounded ones, see OverlayPresentation
        frame.element.style.overflow = "hidden";

        return new EmbeddedOverlay(frame, stack, () -> {
            stack.dispose();

            // the host's own teardown may already have taken the frame down with it
            if (frame.parentComponent != null)
                frame.parentComponent.removeComponent(frame, true);

            if (content.onDismissed != null)
                content.onDismissed();
        });
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
