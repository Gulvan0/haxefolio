package haxefolio.preferences.builder;

import haxe.ui.components.TabBar;
import haxe.ui.core.Component;
import haxe.ui.events.UIEvent;
import haxefolio.preferences.builder.components.PreferenceCloseButton;

/*
    Close-button placement shared by PreferenceModalOverlay and PreferenceSideBarOverlay - the two
    presentations differ only in their container type (VBox vs SideBar) and chrome, the placement
    math itself is identical.
*/
class PreferenceOverlayLayout
{
    /*
        The TabBar's real height depends on measuring its button labels' text metrics, which HaxeUI
        resolves asynchronously - immediately after mounting, tabBar.height still reads as an interim
        value, not its final rendered height. Rather than guess how many frames that takes,
        positioning is tied to the TabBar's own UIEvent.RESIZE, which HaxeUI dispatches on a component
        exactly when its resolved size actually changes - see Component.validateComponentLayout. The
        immediate call handles the common case where nothing was actually pending; the listener
        corrects it once the real height lands.
    */
    public static function attachCloseButtonPositioning(container:Component, content:PreferenceWindowContent, closeButton:PreferenceCloseButton):Void
    {
        var tabBar:TabBar = content.findComponent("tabview-tabs", TabBar);
        tabBar.registerEvent(UIEvent.RESIZE, _ -> positionCloseButton(container, content, tabBar, closeButton));

        container.validateNow();
        positionCloseButton(container, content, tabBar, closeButton);
    }

    /*
        Aligns the close button's vertical center with the tab row's vertical center, and gives it a
        right-inset equal to the content's own left-inset (both ultimately derived from the
        container's single `padding` value in main.css), rather than the button occupying its own row
        with an independent margin that has no relation to the tab row's position or the content's
        insets.

        Centered on [0, tabRowBottom], not [tabRowTop, tabRowBottom]: the container's own top padding
        sits above the TabBar with no visible line separating the two (same background color), so it
        reads as part of the same header area, while tabRowBottom - the tab strip's own bottom border -
        is a crisp, visible edge shared with the content box right below it. Centering only within the
        TabBar's own narrower box would ignore that padding and leave the button looking pulled toward
        the bottom border instead of centered in the header a user actually sees.
    */
    private static function positionCloseButton(container:Component, content:PreferenceWindowContent, tabBar:TabBar, closeButton:PreferenceCloseButton):Void
    {
        var tabRowBottom:Float = tabBar.height;
        var current:Component = tabBar;

        while (current != container)
        {
            tabRowBottom += current.top;
            current = current.parentComponent;
        }

        closeButton.top = (tabRowBottom - closeButton.height) / 2;
        closeButton.left = container.width - content.left - closeButton.width;
    }
}
