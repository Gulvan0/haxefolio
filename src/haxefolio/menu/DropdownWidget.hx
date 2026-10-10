package haxefolio.menu;

import haxe.ui.Toolkit;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.events.MouseEvent;
import haxefolio.ElementShadow;
import haxefolio.ResponsivityController;
import haxefolio.Viewport;
import haxefolio.appearance.AppearanceContext;
import haxefolio.structure.ScrollArea;
import js.Browser;
import js.html.Element;
import js.html.Event;
import js.html.KeyboardEvent;

/**
    A menu bar widget opening a dropdown: a square target showing an icon and an optional count
    badge, and a frame under the menu bar holding the host's content. Give it to the menu bar as a
    persistent widget: `Widget(() -> widget, true)`.

    Expanded, the frame is `expandedWidth` wide, right-aligned to the target; collapsed, it spans the
    viewport minus the edge margins. It sits under the menu bar and is as tall as its content, up to
    the space left above the bottom of the viewport, past which the content scrolls.

    It closes on a click on the target, a pointer press outside the target and the frame, Esc, a
    breakpoint flip, navigation, an overlay being presented and the side bar opening.
**/
class DropdownWidget extends Box
{
    private static inline final GAP_UNDER_BAR:Float = 6;
    private static inline final EDGE_MARGIN:Float = 12;
    private static inline final EXPANDED_BOTTOM_MARGIN:Float = 18;

    private static var openWidget:Null<DropdownWidget> = null;

    public var isOpen(default, null):Bool = false;
    public var onOpened:Void->Void = () -> {};
    public var onClosed:Void->Void = () -> {};

    /** The dropdown, to anchor components added with `attach` to **/
    public final frame:Box;

    private final content:Component;
    private final expandedWidth:Float;
    private final scrollArea:ScrollArea;
    private final badge:Label;

    private var cover:Null<Component> = null;

    /** `content` is laid out at the frame's width, less the scrollbar lane **/
    public function new(icon:Component, content:Component, expandedWidth:Float)
    {
        super();

        this.content = content;
        this.expandedWidth = expandedWidth;

        addClass("haxefolio-dropdown-widget");
        element.setAttribute("role", "button");

        icon.horizontalAlign = "center";
        icon.verticalAlign = "center";
        addComponent(icon);

        badge = new Label();
        badge.addClass("haxefolio-dropdown-widget-badge");
        badge.horizontalAlign = "right";
        badge.verticalAlign = "top";
        badge.hidden = true;
        addComponent(badge);

        content.percentWidth = 100;
        scrollArea = new ScrollArea(content);

        frame = new Box();
        frame.addClass("haxefolio-dropdown-widget-frame");
        frame.addComponent(scrollArea);
        ElementShadow.apply(frame.element, AppearanceContext.current.shadows.menuDropdown);

        registerEvent(MouseEvent.CLICK, _ -> isOpen ? close() : open());

        var contentObserver:Dynamic = js.Syntax.code("new ResizeObserver({0})", _ -> place());
        contentObserver.observe(content.element);

        Browser.document.addEventListener("pointerdown", onDocumentPointerDown, true);
        Browser.document.addEventListener("keydown", onDocumentKeyDown);
        Browser.window.addEventListener("resize", _ -> place());
        ResponsivityController.onCollapseChange(_ -> close());
    }

    /** Closes whichever dropdown is open, if any **/
    @:allow(haxefolio)
    private static function closeOpen():Void
    {
        if (openWidget != null)
            openWidget.close();
    }

    /** Shows `count` on the badge; hidden for 0 **/
    public function setBadgeCount(count:Int):Void
    {
        badge.hidden = count == 0;
        badge.text = Std.string(count);
    }

    /** What assistive technology announces for the target **/
    public function setAccessibleName(name:String):Void
    {
        element.setAttribute("aria-label", name);
    }

    public function open():Void
    {
        if (isOpen)
            return;

        closeOpen();

        isOpen = true;
        openWidget = this;
        addClass("haxefolio-dropdown-widget-open");

        Screen.instance.addComponent(frame);
        ResponsivityController.markRoot(frame);
        place();

        onOpened();
    }

    public function close():Void
    {
        if (!isOpen)
            return;

        isOpen = false;
        openWidget = null;
        removeClass("haxefolio-dropdown-widget-open");

        Screen.instance.removeComponent(frame, false);

        onClosed();
    }

    /**
        Adds `component` to the frame outside its layout, like `NotificationCard.attach`: it takes no
        space and stays where its `left`/`top` put it, relative to the frame's top-left corner (see
        `Anchoring`). Remove it with `detach`.
    **/
    public function attach(component:Component):Void
    {
        component.includeInLayout = false;
        frame.addComponent(component);
    }

    /** Removes a component added with `attach`, disposing it **/
    public function detach(component:Component):Void
    {
        frame.removeComponent(component, true);
    }

    /**
        Shows `component` over the top of the frame at its full width, above the scrolling content,
        which keeps its scroll position; null removes the current one, disposing it.
    **/
    public function setCover(component:Null<Component>):Void
    {
        if (cover != null)
            frame.removeComponent(cover, true);

        cover = component;

        if (component == null)
            return;

        component.percentWidth = 100;
        component.verticalAlign = "top";
        frame.addComponent(component);
    }

    // measured from the DOM, which is what the observer reports on: HaxeUI's own size may lag behind it
    private function place():Void
    {
        if (!isOpen)
            return;

        var collapsed:Bool = ResponsivityController.isCollapsed;
        var barBottom:Float = parentComponent.element.getBoundingClientRect().bottom / Toolkit.scaleY;
        var targetRight:Float = element.getBoundingClientRect().right / Toolkit.scaleX;
        var width:Float = collapsed ? Viewport.width() - 2 * EDGE_MARGIN : expandedWidth;

        frame.width = width;
        frame.left = collapsed ? EDGE_MARGIN : Math.max(EDGE_MARGIN, targetRight - width);
        frame.top = barBottom + GAP_UNDER_BAR;

        var bottomMargin:Float = collapsed ? EDGE_MARGIN : EXPANDED_BOTTOM_MARGIN;
        var maxHeight:Float = Viewport.height() - frame.top - bottomMargin;
        var contentHeight:Float = content.element.getBoundingClientRect().height / Toolkit.scaleY;
        scrollArea.height = Math.min(contentHeight, maxHeight);
    }

    private function onDocumentPointerDown(event:Event):Void
    {
        if (!isOpen)
            return;

        var target:Element = cast event.target;
        if (!frame.element.contains(target) && !element.contains(target))
            close();
    }

    private function onDocumentKeyDown(event:KeyboardEvent):Void
    {
        if (event.key != "Escape" || !isOpen)
            return;

        event.preventDefault();
        close();
    }
}
