package haxefolio.notification;

import haxe.ui.Toolkit;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxefolio.ResponsivityController;
import haxefolio.Viewport;

/*
    Places notifications: one column, anchored to the bottom of the viewport, newest at the bottom
    (closest to the anchor). Expanded, the column sits in the bottom-right corner and each
    notification keeps its own width, right-aligned; collapsed, every notification spans the
    viewport minus the edge margins. Nothing else is shared between notifications - frames, layout
    and lifetime are their content's.

    The column is a Screen root component of its own, added once by HaxeFolioApp.init after the app
    root. Overlays and the side bar are added to Screen only when shown, so they always paint above
    it; the column is made inert along with the app root while either is open, as part of the app
    beneath them.

    It is re-anchored whenever its own size changes (which covers showing, dismissing, and content
    changing its height), on the debounced viewport resize, and when the breakpoint flips. Its own
    size changes are watched with a native ResizeObserver: HaxeUI's UIEvent.RESIZE did not fire
    when the column, auto-sized to its content, grew after the first layout, which left it anchored
    for a height of 0 (below the viewport's bottom edge).
*/
class NotificationLayer
{
    private static inline final EDGE_MARGIN:Int = 12;
    private static inline final GAP:Int = 10;

    private static var column:VBox;
    private static var shown:Array<Notification> = [];

    /*
        Creates the column and adds it to Screen. Returns it, so the caller can make it inert
        together with the rest of the app.
    */
    @:allow(haxefolio)
    private static function init():Component
    {
        column = new VBox();
        column.id = "haxefolio-notification-layer";
        column.addClass("haxefolio-notification-layer");
        column.verticalSpacing = GAP;
        column.hidden = true;

        Screen.instance.addComponent(column);

        var observer:Dynamic = js.Syntax.code("new ResizeObserver({0})", onColumnResized);
        observer.observe(column.element);

        ResponsivityController.onCollapseChange(_ -> fit());

        return column;
    }

    @:allow(haxefolio)
    private static function show(content:Component, expandedWidth:Float):Notification
    {
        var notification:Notification = new Notification(content, expandedWidth);
        shown.push(notification);

        content.horizontalAlign = "right";
        column.addComponent(content);
        column.hidden = false;

        fit();

        return notification;
    }

    @:allow(haxefolio.notification)
    private static function remove(notification:Notification):Void
    {
        if (!shown.remove(notification))
            return;

        column.removeComponent(notification.content, false);
        column.hidden = shown.length == 0;

        fit();
    }

    /*
        Applies the current breakpoint's widths and re-anchors the column. Called off the debounced
        viewport resize too.
    */
    @:allow(haxefolio)
    private static function fit():Void
    {
        if (shown.length == 0)
            return;

        var collapsedWidth:Float = Viewport.width() - 2 * EDGE_MARGIN;
        var columnWidth:Float = 0;

        for (notification in shown)
        {
            var width:Float = ResponsivityController.isCollapsed ? collapsedWidth : notification.expandedWidth;
            notification.content.width = width;
            columnWidth = Math.max(columnWidth, width);
        }

        column.width = columnWidth;
        anchor();
    }

    private static function onColumnResized(_:Array<Dynamic>):Void
    {
        anchor();
    }

    // measured from the DOM, which is what the observer reports on: HaxeUI's own size may lag behind it
    private static function anchor():Void
    {
        if (shown.length == 0)
            return;

        var width:Float = column.element.offsetWidth / Toolkit.scaleX;
        var height:Float = column.element.offsetHeight / Toolkit.scaleY;

        column.left = Viewport.width() - EDGE_MARGIN - width;
        column.top = Viewport.height() - EDGE_MARGIN - height;
    }
}
