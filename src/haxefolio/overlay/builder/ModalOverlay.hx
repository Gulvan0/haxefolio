package haxefolio.overlay.builder;

import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.overlay.builder.components.OverlayCloseButton;

/*
    Desktop presentation: a centered, non-blocking modal - a plain VBox added directly to the page
    container, scoped to its bounds and never touching the page itself. Deliberately bypasses
    HaxeUI's Window/WindowManager: no drag, resize, collapse, or window-manager bookkeeping.

    Deliberately non-blocking: no backdrop component at all, and no Screen.instance reparenting -
    `modal` stays exactly where it is, a pageContainer child, positioned via
    horizontalAlign/verticalAlign. The rest of the app - menu bar and page underneath included -
    stays fully clickable while the modal is open; the modal only ever captures clicks landing on
    its own box (see `modal.recursivePointerEvents` below), never any further than that. There is
    therefore no click-outside-to-dismiss - closing it is only possible via its close button, a
    `dismiss()` call from its own content, or a navigation (HaxeFolioApp.switchToPage
    force-dismisses any open overlay before swapping pages).

    A fresh modal is built on every call, so it is the caller's (HaxeFolioApp.showOverlay's)
    responsibility to not call this again before `onDismissed` fires for a previous call, or the
    modals would stack up on top of each other.

    `@:access(haxe.ui.core.Component)` is needed to reach `recursivePointerEvents` (private, no
    public setter) - see its use on `modal` below.
*/
@:access(haxe.ui.core.Component)
class ModalOverlay
{
    public static function show(slug:String, pageContainer:Component, content:OverlayContent, ?width:Int, ?height:Int, showCloseButton:Bool, ?closeButtonSize:Int, ?closeButtonInsetX:Int, ?closeButtonInsetY:Int, onDismissed:Void->Void):Void->Void
    {
        var modal:VBox = new VBox();
        modal.id = 'haxefolio-overlay-$slug-modal';
        modal.addClass("haxefolio-overlay-modal");
        modal.horizontalAlign = "center";
        modal.verticalAlign = "center";

        if (width != null)
            modal.width = width;

        if (height != null)
            modal.height = height;

        /*
            `.haxefolio-overlay-modal`'s `pointer-events: true` (main.css) is there so clicks on
            the modal's own background/padding don't fall through to whatever page content happens
            to be rendered beneath it at that screen position. That style also defaults
            `recursivePointerEvents` to true, which makes HaxeUI stamp the `:hover`/`:down`
            pseudo-classes onto every descendant whenever the modal itself is hovered/pressed - not
            just the actual hovered/pressed child. Disabling it here keeps the click-catching
            behavior while confining hover/press styling to the element the pointer is actually
            over, same fix HaxeUI's own Collapsible applies to its header for the same reason.
        */
        modal.recursivePointerEvents = false;

        content.id = 'haxefolio-overlay-$slug-content';
        content.addClass("haxefolio-overlay-content");

        function dismiss():Void
        {
            content.dispose();
            pageContainer.removeComponent(modal, true);
            onDismissed();
        }

        modal.addComponent(content);

        var closeButton:Null<OverlayCloseButton> = showCloseButton
            ? new OverlayCloseButton('haxefolio-overlay-$slug-close-button', dismiss, closeButtonSize)
            : null;

        if (closeButton != null)
        {
            /*
                Floated (`includeInLayout = false`) rather than laid out as its own row, so it can
                sit on top of the content instead of pushing it down - see OverlayLayout, which is
                what actually places it once real geometry is known.
            */
            closeButton.includeInLayout = false;

            /*
                Guards against any inherited margin offsetting the DOM position on top of the exact
                `left`/`top` OverlayLayout computes below.
            */
            closeButton.customStyle.marginLeft = 0;
            closeButton.customStyle.marginTop = 0;

            modal.addComponent(closeButton);
        }

        pageContainer.addComponent(modal);

        if (closeButton != null)
            OverlayLayout.attachCloseButtonPositioning(modal, content, closeButton, closeButtonInsetX, closeButtonInsetY);

        return dismiss;
    }
}
