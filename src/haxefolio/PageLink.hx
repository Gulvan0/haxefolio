package haxefolio;

import haxe.ui.core.Component;
import js.Browser;
import js.html.AnchorElement;
import js.html.MouseEvent;

/**
    Makes a component a real link to a page: an invisible `<a href>` covering it, so the browser
    offers "Open in new tab", "Copy link address" and shows the target URL on hover.

    An unmodified left click navigates through `HaxeFolioApp.navigateTo`, keeping the app running;
    every other click (Ctrl/Cmd/Shift/Alt, middle button) is left to the browser, which opens
    the page by its URL. The component's own click handler is not involved: don't assign one.
**/
class PageLink
{
    private final component:Component;
    private final anchor:AnchorElement;
    private final onFollowed:Null<Void->Void>;
    private var path:Null<String> = null;
    private var fragment:Null<String> = null;
    private var state:Null<Dynamic> = null;

    /**
        Covers `component` with a link to `path`; `null` makes it a non-link until `setPath`.
        The anchor spans the component's bounds at all times and takes pointer events away from
        the descendants: call `keepInteractive` on those that must stay usable or show tooltips.
        `onFollowed` runs before an in-app navigation, not before one the browser performs.
        A disabled component swallows clicks; to also drop its context menu, `setPath(null)`.
    **/
    public static function attach(component:Component, path:Null<String>, ?fragment:String, ?state:Dynamic, ?onFollowed:Void->Void):PageLink
    {
        var link:PageLink = new PageLink(component, onFollowed);
        link.setPath(path, fragment, state);
        return link;
    }

    /** Retargets the link; `null` removes it, leaving the component and its descendants plain **/
    public function setPath(path:Null<String>, ?fragment:String, ?state:Dynamic):Void
    {
        this.path = path;
        this.fragment = fragment;
        this.state = state;

        if (path == null)
        {
            anchor.removeAttribute("href");
            anchor.style.display = "none";
        }
        else
        {
            anchor.href = HaxeFolioApp.pageUrl(path, fragment);
            anchor.style.display = "block";
        }
    }

    /** Raises a descendant of the component above the link, so it receives the pointer itself **/
    public function keepInteractive(descendant:Component):Void
    {
        descendant.element.style.zIndex = "2";
    }

    /** Removes the link; a disposed component needs no call **/
    public function detach():Void
    {
        anchor.removeEventListener("click", onClicked);
        anchor.removeEventListener("auxclick", onAuxiliaryClicked);
        anchor.remove();
    }

    private function new(component:Component, onFollowed:Null<Void->Void>)
    {
        this.component = component;
        this.onFollowed = onFollowed;

        anchor = cast Browser.document.createElement("a");
        anchor.draggable = false;
        anchor.tabIndex = -1;
        anchor.style.cssText = "position: absolute; left: 0; top: 0; right: 0; bottom: 0; z-index: 1; outline: none; -webkit-user-drag: none;";
        anchor.addEventListener("click", onClicked);
        anchor.addEventListener("auxclick", onAuxiliaryClicked);
        component.element.appendChild(anchor);
    }

    private function onClicked(event:MouseEvent):Void
    {
        if (component.disabled)
        {
            event.preventDefault();
            return;
        }

        if (event.defaultPrevented || event.button != 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey)
            return;

        event.preventDefault();

        if (onFollowed != null)
            onFollowed();

        HaxeFolioApp.navigateTo(path, state, fragment);
    }

    private function onAuxiliaryClicked(event:MouseEvent):Void
    {
        if (component.disabled)
            event.preventDefault();
    }
}
