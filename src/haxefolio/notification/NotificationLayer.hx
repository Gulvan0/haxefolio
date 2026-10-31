package haxefolio.notification;

import haxe.ui.Toolkit;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxefolio.MenuLayout;
import haxefolio.ResponsivityController;
import haxefolio.Viewport;

/*
    Places notifications: one column, anchored to the bottom of the viewport, newest at the bottom
    (closest to the anchor). Expanded and in the rail layout, the column sits in the bottom-right
    corner and each notification keeps its own width, right-aligned; collapsed, every notification
    spans the viewport minus the edge margins. Nothing else is shared between notifications - frames, layout
    and lifetime are their content's.

    The column is a Screen root component of its own, added once by HaxeFolioApp.init after the app
    root. It paints above everything else on Screen - overlays and the side bar included, although
    they are added later - and is never made inert: a notification is often the outcome of an
    action taken inside an overlay (a failed request, say), and must stay readable and dismissable
    over it. Hence its z-index, set above the small ones pages use internally (see PageLink), which
    compete with it unless something in between forms a stacking context.

    It is re-anchored whenever its own size changes (which covers showing, dismissing, and content
    changing its height), on the debounced viewport resize, and when the layout changes. Its own
    size changes are watched with a native ResizeObserver: HaxeUI's UIEvent.RESIZE did not fire
    when the column, auto-sized to its content, grew after the first layout, which left it anchored
    for a height of 0 (below the viewport's bottom edge).
*/
class NotificationLayer
{
    private static inline final EDGE_MARGIN:Int = 12;
    private static inline final GAP:Int = 10;
    private static inline final Z_INDEX:String = "100";

    private static var column:VBox;
    private static var shown:Array<Notification> = [];
    private static var bottomInset:Float = 0;

    /*
        Creates the column and adds it to Screen
    */
    @:allow(haxefolio)
    private static function init():Void
    {
        column = new VBox();
        column.id = "haxefolio-notification-layer";
        column.addClass("haxefolio-notification-layer");
        column.verticalSpacing = GAP;
        column.hidden = true;

        Screen.instance.addComponent(column);
        column.element.style.zIndex = Z_INDEX;

        var observer:Dynamic = js.Syntax.code("new ResizeObserver({0})", onColumnResized);
        observer.observe(column.element);

        ResponsivityController.onMenuLayoutChange(_ -> fit());
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

    @:allow(haxefolio)
    private static function setBottomInset(inset:Float):Void
    {
        bottomInset = inset;
        anchor();
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
        Applies the current layout's widths and re-anchors the column. Called off the debounced
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
            var width:Float = ResponsivityController.menuLayout == Collapsed ? collapsedWidth : notification.expandedWidth;
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
        column.top = Viewport.height() - EDGE_MARGIN - bottomInset - height;
    }
}
