package haxefolio.preferences.builder;

import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.preferences.builder.components.PreferenceCloseButton;

/*
    Desktop presentation: a centered, non-blocking modal - a plain VBox over a semi-transparent
    backdrop, both added directly to the page container so they stay scoped to its bounds and never
    touch the page itself. Deliberately bypasses HaxeUI's Window/WindowManager: no drag, resize,
    collapse, or window-manager bookkeeping - just a close button plus dismiss-by-clicking-the-backdrop.

    A fresh modal+backdrop pair is built on every call, so it is the caller's
    (HaxeFolioApp.showPreferences') responsibility to not call this again before `onDismissed` fires
    for a previous call, or the pairs would stack up on top of each other.

    `@:access(haxe.ui.core.Component)` is needed to reach `recursivePointerEvents` (private, no
    public setter) - see its use on `modal` below.
*/
@:access(haxe.ui.core.Component)
class PreferenceModalOverlay
{
    private static inline var MODAL_WIDTH:Int = 480;
    private static inline var MODAL_HEIGHT:Int = 360;

    public static function show(pageContainer:Component, tabIcons:Map<String, String>, onDismissed:Void->Void):Void
    {
        var content:PreferenceWindowContent = PreferenceWindowBuilder.build(tabIcons);

        var modal:VBox = new VBox();
        modal.id = "haxefolio-preference-modal";
        modal.addClass("haxefolio-preference-modal");
        modal.horizontalAlign = "center";
        modal.verticalAlign = "center";
        modal.width = MODAL_WIDTH;
        modal.height = MODAL_HEIGHT;

        /*
            `.haxefolio-preference-modal`'s `pointer-events: true` (main.css) is there so clicks on
            the modal's own background/padding don't fall through to the backdrop and dismiss it.
            That style also defaults `recursivePointerEvents` to true, which makes HaxeUI stamp the
            `:hover`/`:down` pseudo-classes onto every descendant whenever the modal itself is
            hovered/pressed - not just the actual hovered/pressed child. Disabling it here keeps the
            click-catching behavior while confining hover/press styling to the element the pointer is
            actually over, same fix HaxeUI's own Collapsible applies to its header for the same reason.
        */
        modal.recursivePointerEvents = false;

        var backdrop:Component = new Component();
        backdrop.id = "haxefolio-preference-backdrop";
        backdrop.addClass("modal-background");
        backdrop.addClass("haxefolio-preference-backdrop");
        backdrop.percentWidth = 100;
        backdrop.percentHeight = 100;

        function dismiss():Void
        {
            content.dispose();
            pageContainer.removeComponent(backdrop, true);
            pageContainer.removeComponent(modal, true);
            onDismissed();
        }

        /*
            Floated (`includeInLayout = false`) rather than laid out as its own row above the tabs,
            so it can sit on the same line as the tab row instead of pushing it down - see
            PreferenceOverlayLayout, which is what actually places it once real geometry is known.
        */
        var closeButton:PreferenceCloseButton = new PreferenceCloseButton(dismiss);
        closeButton.includeInLayout = false;

        /*
            `.haxefolio-preference-close-button`'s `margin: 8px` (main.css, shared with the SideBar
            presentation) would otherwise still offset the DOM position on top of the exact
            `left`/`top` computed below - see the "amount of ... offset to apply to the calculated
            position" doc on Style.marginLeft/marginTop. Cleared per-instance rather than in the
            shared CSS class, which the SideBar presentation still relies on for its own margin.
        */
        closeButton.customStyle.marginLeft = 0;
        closeButton.customStyle.marginTop = 0;

        modal.addComponent(content);
        modal.addComponent(closeButton);

        backdrop.onClick = _ -> dismiss();

        pageContainer.addComponent(backdrop);
        pageContainer.addComponent(modal);

        PreferenceOverlayLayout.attachCloseButtonPositioning(modal, content, closeButton);
    }
}
