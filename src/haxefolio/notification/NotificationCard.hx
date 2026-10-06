package haxefolio.notification;

import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.ByWidth;
import haxefolio.ElementShadow;
import haxefolio.ResponsivityController;
import haxefolio.appearance.AppearanceContext;
import haxefolio.structure.ActionButton;
import morestd.Detachable;

/**
    The parts most notifications share, as one card: a surface frame, a header - an optional
    `caption` line over a `title`, with a close control once `onClose` is set - a body for the
    host's own content, and a row of `ActionButton`s split evenly. Show it with
    `HaxeFolioApp.notify`, alone or as one card of a bigger notification.

    It follows the breakpoint by itself: collapsed, it carries `haxefolio-notification-card-collapsed`
    (the close control's larger hit area is styled on it) and its buttons take the collapsed
    `fieldHeight`.

    Declared in XML as `<notification-card caption="..." title="...">`, its child elements go into
    the body, except `<action-button>`s, which go into the action row. From code, add content with
    `addComponent` the same way, or through `body` / `addAction`. Something that hangs off the card
    instead - a popover beside or above it - goes through `attach`.
**/
class NotificationCard extends VBox
{
    private static inline final SHADOW:String = "0 8px 28px rgba(24, 26, 31, 0.16)";

    /**
        The small line above the title (e.g. "Challenge from"), or null for none. Interpreted like
        any HaxeUI `.text` property (see `LocaleUtils`).
    **/
    public var caption(get, set):Null<String>;

    /**
        The card's title, interpreted like any HaxeUI `.text` property.
    **/
    public var title(get, set):String;

    /**
        What the close control calls. The control is shown only while this is set.
    **/
    public var onClose(default, set):Null<Void->Void> = null;

    /**
        The host's content, between the header and the actions.
    **/
    public final body:VBox;

    private final captionLabel:Label;
    private final titleLabel:Label;
    private final closeButton:Button;
    private final actions:HBox;
    private final actionButtons:Array<ActionButton> = [];

    private var breakpointBinding:Detachable;
    private var buttonHeightBinding:Detachable;

    public function new()
    {
        super();

        addClass("haxefolio-notification-card");
        percentWidth = 100;
        ElementShadow.apply(element, SHADOW);

        var header:HBox = new HBox();
        header.percentWidth = 100;
        header.addClass("haxefolio-notification-card-header");
        super.addComponent(header);

        var headings:VBox = new VBox();
        headings.percentWidth = 100;
        headings.addClass("haxefolio-notification-card-headings");
        header.addComponent(headings);

        captionLabel = new Label();
        captionLabel.percentWidth = 100;
        captionLabel.addClass("haxefolio-notification-card-caption");
        captionLabel.hidden = true;
        headings.addComponent(captionLabel);

        titleLabel = new Label();
        titleLabel.percentWidth = 100;
        titleLabel.addClass("haxefolio-notification-card-title");
        headings.addComponent(titleLabel);

        // its negative margins (main.css) let it overhang the header rather than make it taller
        closeButton = new Button();
        closeButton.text = "✕";
        closeButton.addClass("haxefolio-notification-card-close");
        closeButton.hidden = true;
        closeButton.onClick = _ -> {
            if (onClose != null)
                onClose();
        };
        header.addComponent(closeButton);

        body = new VBox();
        body.percentWidth = 100;
        body.addClass("haxefolio-notification-card-body");
        super.addComponent(body);

        actions = new HBox();
        actions.percentWidth = 100;
        actions.addClass("haxefolio-notification-card-actions");
        actions.hidden = true;
        super.addComponent(actions);

        var breakpoint:ByWidth<Bool> = {expanded: false, collapsed: true};
        breakpointBinding = ResponsivityController.bind(breakpoint, collapsed -> {
            if (collapsed)
                addClass("haxefolio-notification-card-collapsed");
            else
                removeClass("haxefolio-notification-card-collapsed");
        });
        buttonHeightBinding = ResponsivityController.bind(AppearanceContext.current.geometry.fieldHeight, applyButtonHeight);
    }

    /**
        Adds `button` to the action row. The row's buttons share its width evenly.
    **/
    public function addAction(button:ActionButton):Void
    {
        actionButtons.push(button);
        actions.addComponent(button);
        actions.hidden = false;

        for (actionButton in actionButtons)
            actionButton.percentWidth = 100 / actionButtons.length;

        applyButtonHeight(AppearanceContext.current.geometry.fieldHeight.resolve(ResponsivityController.isCollapsed));
    }

    /**
        Adds `component` to the card outside its layout: it takes no space and stays wherever its
        `left`/`top` put it, relative to the card's top-left corner - outside the card's bounds too,
        since the card doesn't clip. It moves with the card. Remove it with `detach`.
    **/
    public function attach(component:Component):Void
    {
        component.includeInLayout = false;
        super.addComponent(component);
    }

    /**
        Removes a component added with `attach`, disposing it.
    **/
    public function detach(component:Component):Void
    {
        super.removeComponent(component, true);
    }

    /*
        Content added to the card itself - from XML or code - goes into the body, and ActionButtons
        into the action row; the header, body and action row themselves are added with super's.
    */
    public override function addComponent(child:Component):Component
    {
        if (Std.isOfType(child, ActionButton))
        {
            addAction(cast child);
            return child;
        }

        return body.addComponent(child);
    }

    private override function onDestroy():Void
    {
        breakpointBinding.detach();
        buttonHeightBinding.detach();
        super.onDestroy();
    }

    private function applyButtonHeight(height:Int):Void
    {
        for (button in actionButtons)
            button.height = height;
    }

    private function get_caption():Null<String>
    {
        return captionLabel.hidden ? null : captionLabel.text;
    }

    private function set_caption(value:Null<String>):Null<String>
    {
        captionLabel.text = value;
        captionLabel.hidden = value == null;
        return value;
    }

    private function get_title():String
    {
        return titleLabel.text;
    }

    private function set_title(value:String):String
    {
        titleLabel.text = value;
        return value;
    }

    private function set_onClose(value:Null<Void->Void>):Null<Void->Void>
    {
        onClose = value;
        closeButton.hidden = value == null;
        return value;
    }
}
