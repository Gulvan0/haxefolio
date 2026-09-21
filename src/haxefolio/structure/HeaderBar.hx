package haxefolio.structure;

import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxefolio.appearance.AppearanceContext;

/**
    The title row of an overlay: the title on the left and, unless there is nothing to close, a close
    control on the right, both centred vertically. It is what the `Header` region of a
    `RegionStack` holds.

    The title is a single line and is not truncated - there is no ellipsis to fall back on - so a
    title too long for the row pushes the close control out of it. Keep titles short.
**/
class HeaderBar extends HBox
{
    private final titleLabel:Label;

    /**
        The title text, interpreted like any HaxeUI `.text` property (see `LocaleUtils`).
    **/
    public var title(get, set):String;

    /**
        `onClose` is what the close control calls; leave it out for a header with none (nothing
        to dismiss - an embedded panel - or a host that gives the overlay its own exit).
    **/
    public function new(title:String, ?onClose:Void->Void, ?closeButtonId:String)
    {
        super();

        this.percentWidth = 100;
        this.percentHeight = 100;
        this.paddingLeft = AppearanceContext.current.geometry.padding;
        this.paddingRight = AppearanceContext.current.geometry.padding;
        this.addClass("haxefolio-header-bar");

        titleLabel = new Label();
        titleLabel.verticalAlign = "center";
        titleLabel.percentWidth = 100; // takes the row's slack, which pushes the close control to the right edge
        titleLabel.addClass("haxefolio-header-title");
        this.addComponent(titleLabel);

        this.title = title;

        if (onClose != null)
        {
            var closeButton:Button = new Button();
            closeButton.text = "✕";
            closeButton.verticalAlign = "center";
            closeButton.addClass("haxefolio-close-button");
            closeButton.onClick = _ -> onClose();

            if (closeButtonId != null)
                closeButton.id = closeButtonId;

            this.addComponent(closeButton);
        }
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
}
