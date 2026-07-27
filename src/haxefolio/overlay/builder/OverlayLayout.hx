package haxefolio.overlay.builder;

import haxe.ui.core.Component;
import haxefolio.overlay.builder.components.OverlayCloseButton;

/*
    Close-button placement shared by ModalOverlay and SideBarOverlay - the two presentations differ
    only in their container type and chrome, the placement math itself is identical: always flush
    at the container's top-right corner, inset from it by insetX/insetY (or, when either is
    omitted, by the container's own live padding - content.left/content.top - so the button lines
    up with the content's own edge by default).
*/
class OverlayLayout
{
    /*
        No resize listener is needed here, unlike the TabBar-height-driven positioning this
        replaced: container.width/height are always an explicit pixel value the caller passed in -
        the modal's own width/height, or the sidebar's live document.body measurement (see
        SideBarOverlay) - and content.left/content.top are plain CSS padding values - all
        synchronous layout math resolved by validateNow(). Don't reintroduce a resize listener here
        without a similar asynchronous-measurement reason to justify it.
    */
    public static function attachCloseButtonPositioning(container:Component, content:Component, closeButton:OverlayCloseButton, insetX:Null<Int>, insetY:Null<Int>):Void
    {
        container.validateNow();

        closeButton.left = container.width - (insetX ?? content.left) - closeButton.width;
        closeButton.top = insetY ?? content.top;
    }
}
