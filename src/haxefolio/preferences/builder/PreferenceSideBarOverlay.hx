package haxefolio.preferences.builder;

import haxe.ui.containers.SideBar;
import haxe.ui.core.Screen;
import haxe.ui.events.UIEvent;
import haxefolio.preferences.builder.components.PreferenceCloseButton;

/*
    Mobile presentation: a SideBar sliding up from the bottom, sized to cover the entire viewport
    (including the menu bar) via `method = "float"`, which leaves the page container's own size
    untouched rather than shifting/resizing it. The page container and its current page are never
    touched here, so the page keeps running/redrawing underneath and is never destroyed; navigation
    state and the URL are untouched too. A dedicated close button dismisses the panel.

    A fresh SideBar is built on every call, so it is the caller's (HaxeFolioApp.showPreferences')
    responsibility to not call this again before `onDismissed` fires for a previous call - HaxeUI's
    own SideBar tracks only one `activeSideBar` at a time, so two coexisting instances fighting over
    that single slot produces visibly broken show/hide animations.
*/
class PreferenceSideBarOverlay
{
    public static function show(tabIcons:Map<String, String>, onDismissed:Void->Void):Void
    {
        var content:PreferenceWindowContent = PreferenceWindowBuilder.build(tabIcons);

        var sideBar:SideBar = new SideBar();
        sideBar.id = "haxefolio-preference-sidebar";
        sideBar.addClass("haxefolio-preference-sidebar");
        sideBar.position = "bottom";
        sideBar.method = "float";
        sideBar.percentWidth = 100;
        sideBar.height = Screen.instance.actualHeight;

        /*
            Floated (`includeInLayout = false`) rather than laid out as its own row above the tabs,
            so it doesn't push the content down by its own row height - see PreferenceOverlayLayout,
            which is what actually places it once real geometry is known.
        */
        var closeButton:PreferenceCloseButton = new PreferenceCloseButton(() ->
        {
            content.dispose();
            sideBar.hide();
        });
        closeButton.includeInLayout = false;

        /*
            `.haxefolio-preference-close-button`'s `margin: 8px` (main.css) would otherwise still
            offset the DOM position on top of the exact `left`/`top` computed below.
        */
        closeButton.customStyle.marginLeft = 0;
        closeButton.customStyle.marginTop = 0;

        /*
            No intermediate wrapper needed: content is already percentWidth/percentHeight 100 (see
            PreferenceWindowBuilder), and the floated closeButton is positioned independently of
            normal box layout either way.
        */
        sideBar.addComponent(content);
        sideBar.addComponent(closeButton);

        /*
            SideBar.hide() only animates + hides; since a fresh SideBar is built on every
            showPreferences() call, it must also be pruned from the screen once the hide animation
            completes, or repeated opens would keep piling up hidden SideBars. This is also the
            single point at which the panel is fully gone, so it doubles as the `onDismissed` signal
            that lets the caller allow a new show() call again.
        */
        sideBar.registerEvent(UIEvent.HIDDEN, _ ->
        {
            Screen.instance.removeComponent(sideBar, true);
            onDismissed();
        });

        sideBar.show();

        PreferenceOverlayLayout.attachCloseButtonPositioning(sideBar, content, closeButton);
    }
}
