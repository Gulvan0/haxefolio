package haxefolio.overlay;

import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.InertHolds;
import haxefolio.menu.DropdownWidget;
import haxefolio.appearance.AppearanceContext;
import haxefolio.appearance.AppearanceOverrides;
import haxefolio.appearance.GeometryTokens;
import haxefolio.appearance.ShadowTokens;
import haxefolio.overlay.builder.DialogPresentation;
import haxefolio.overlay.builder.OverlayPresentation;
import haxefolio.overlay.builder.SheetPresentation;
import haxefolio.structure.RegionStack;
import js.Browser;
import js.html.KeyboardEvent;
import morestd.Detachable;

/*
    The framework's open overlays: builds the content, picks a presentation, and owns everything
    that is the same in both - the no-op while one is already open, Esc, and making the rest of
    the app unreachable. HaxeFolioApp.present/dismissing on navigation are thin wrappers over this.

    Normally there is one overlay at a time. A host that needs a second one over the first (a
    picker opened from a form) presents it `nested`: it stacks on the topmost overlay, which is
    made unreachable like the app, and only the topmost reacts to Esc. Dismissing an overlay
    dismisses those above it first.

    Making the rest of the app unreachable is done by marking its root components `inert`, rather
    than by a scrim's pointer-events: `inert` takes them out of hit-testing, the tab order and
    assistive technology at once - which is the scrim, focus trap and scroll lock of a modal in one
    attribute, and holds for the whole show -> gone window, sheet slide-out included. The frame and
    scrim are Screen root components of their own, so they are not affected; a nested overlay marks
    the roots of the one beneath it. The attribute goes through InertHolds, since the menu side bar
    makes the app inert too.

    Presentation (dialog or sheet) is picked once, by ResponsivityController.menuLayout at the
    moment of presenting - a sheet unless Expanded - and fixed for that overlay's lifetime: swapping live would have to rebuild
    the content from the other factory and lose whatever the user had typed.
*/
class OverlayController
{
    private static var inertComponents:Array<Component> = [];
    private static var openOverlays:Array<OpenOverlay> = []; // bottom to top, closing ones included

    // open or closing; read by the menu side bar, which leaves Esc to an overlay presented over it
    @:allow(haxefolio)
    private static var isOpen(get, never):Bool;

    /*
        Registers the app's own root components, which are marked inert while an overlay is open.
        Called once by HaxeFolioApp.init.
    */
    public static function init(inertComponents:Array<Component>):Void
    {
        OverlayController.inertComponents = inertComponents;
    }

    public static function present(slug:String, contentFactory:(Void->Void)->OverlayContent, ?mobileContentFactory:(Void->Void)->OverlayContent, ?appearance:AppearanceOverrides, ?onDismissed:Void->Void, nested:Bool = false):Void
    {
        var below:Null<OpenOverlay> = openOverlays[openOverlays.length - 1];

        if (nested ? (below == null || below.isClosing || isOpenWithSlug(slug)) : below != null)
            return;

        DropdownWidget.closeOpen();

        var isCollapsed:Bool = ResponsivityController.menuLayout != Expanded;
        var factory:(Void->Void)->OverlayContent = (isCollapsed && mobileContentFactory != null) ? mobileContentFactory : contentFactory;

        var overlay:OpenOverlay = new OpenOverlay(slug);
        openOverlays.push(overlay);

        function dismiss():Void
        {
            if (overlay.isClosing || overlay.presentation == null)
                return;

            // what is above goes first: it was opened from this one
            var above:Array<OpenOverlay> = openOverlays.slice(openOverlays.indexOf(overlay) + 1);
            above.reverse();
            for (other in above)
                other.requestDismissal();

            overlay.isClosing = true;
            overlay.presentation.hide();
        }

        overlay.requestDismissal = dismiss;

        function onKeyDown(event:KeyboardEvent):Void
        {
            if (event.key != "Escape" || openOverlays[openOverlays.length - 1] != overlay)
                return;

            event.preventDefault();
            event.stopPropagation();
            dismiss();
        }

        var content:Null<OverlayContent> = null;
        var stack:RegionStack;
        var geometry:Null<GeometryTokens> = null;
        var shadows:Null<ShadowTokens> = null;

        // built under the overlay's own appearance, so every component reads it (see AppearanceContext)
        try
        {
            stack = AppearanceContext.runWith(appearance, () -> {
                geometry = AppearanceContext.current.geometry;
                shadows = AppearanceContext.current.shadows;
                content = factory(dismiss);
                return new RegionStack(content.regions, 0, dismiss, 'haxefolio-overlay-$slug');
            });
        }
        catch (e:Dynamic)
        {
            openOverlays.remove(overlay);

            if (content != null && content.onDismissed != null)
                content.onDismissed();

            throw e;
        }

        var inertHold:Null<Detachable> = null;

        function onGone():Void
        {
            stack.dispose();
            inertHold.detach();

            Browser.document.removeEventListener("keydown", onKeyDown, true);

            openOverlays.remove(overlay);
            overlay.presentation = null;

            if (content.onDismissed != null)
                content.onDismissed();

            if (onDismissed != null)
                onDismissed();
        }

        var styleClass:Null<String> = appearance?.styleClass;

        overlay.presentation = isCollapsed
            ? new SheetPresentation(slug, stack, styleClass, shadows.sheet, below != null, onGone)
            : new DialogPresentation(slug, stack, styleClass, geometry.dialogWidth, geometry.dialogHeight, shadows.dialog, below?.presentation, onGone);

        inertHold = InertHolds.hold(below != null ? below.presentation.roots() : inertComponents);

        // capture phase, so Esc reaches this before anything inside the overlay can swallow it
        Browser.document.addEventListener("keydown", onKeyDown, true);

        overlay.presentation.show();
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
        Closes every open overlay, if any - used when the page changes underneath them. Safe to call
        while one is already closing.
    */
    public static function dismissIfOpen():Void
    {
        for (overlay in openOverlays.copy())
            overlay.requestDismissal();
    }

    /*
        Re-fits the open overlays' frames to the viewport, bottom to top, each nested one against
        the frame beneath it. Called off the same debounced resize signal ResponsivityController
        already computes.
    */
    public static function resize():Void
    {
        for (overlay in openOverlays)
            if (overlay.presentation != null)
                overlay.presentation.resize();
    }

    private static function isOpenWithSlug(slug:String):Bool
    {
        for (overlay in openOverlays)
            if (overlay.slug == slug)
                return true;

        return false;
    }

    private static function get_isOpen():Bool
    {
        return openOverlays.length > 0;
    }
}

private class OpenOverlay
{
    public final slug:String;
    public var presentation:Null<OverlayPresentation> = null;
    public var requestDismissal:Void->Void;
    public var isClosing:Bool = false;

    public function new(slug:String)
    {
        this.slug = slug;
    }
}
