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

        /*
            A second, immediate pass - not a stray leftover. Overlay content built around a
            haxeui-core `TabView` can still have a stale `content.top` after the first
            validateNow(): TabView.Layout.repositionChildren only offsets its content pane by
            `tabs.height` `if (tabs.height != 0)`, and on this container's very first synchronous
            validation the TabBar's own height hasn't resolved yet, so that offset gets skipped and
            never revisited on its own. Re-validating here works around it without reaching into
            haxeui-core's TabView itself; validateNow() is otherwise a no-op once a component is
            already clean, so this costs nothing when content has no such not-yet-settled
            descendant.
        */
        container.validateNow();

        closeButton.left = container.width - (insetX ?? content.left) - closeButton.width;
        closeButton.top = insetY ?? content.top;
    }
}
