package haxefolio.structure;

import haxe.ui.components.Button;
import haxefolio.appearance.AppearanceContext;

/*
    One button of an ActionBar. Either an ordinary action (the unselected ChoiceButton look) or the
    primary one, drawn per the app's `actionEmphasis` - read from AppearanceContext when built, so
    it agrees with CommitTextField's commit button (the other component sharing that role).

    A disabled button loses its emphasis: a primary action that cannot be taken right now must not
    still read as the thing to press (see the `:disabled` rules in main.css).
*/
class ActionButton extends Button
{
    /**
        Whether the button can be pressed. A disabled button greys out in place and, if primary,
        loses its emphasis.
    **/
    public var enabled(get, set):Bool;

    /**
        Whether this is the bar's primary action, drawn per the app's `actionEmphasis` (read from
        AppearanceContext when set). Settable from XML (`primary="true"`).
    **/
    public var primary(default, set):Bool = false;

    /**
        All arguments are optional, so the button can also be declared in XML - there, `text`,
        `primary`, `icon`, `width` and `disabled` are attributes, and the handler is attached in code
        through `onClick`. `widthPercent` is the button's share of its bar's width; leave it out to
        split whatever the bar's other buttons leave evenly (see `ActionBar`).
    **/
    public function new(?caption:String, ?onPress:Void->Void, primary:Bool = false, ?glyph:String, ?widthPercent:Float, initiallyEnabled:Bool = true)
    {
        super();

        this.addClass("haxefolio-action-button");

        if (caption != null)
            this.text = caption;

        this.primary = primary;

        if (glyph != null)
            this.icon = glyph;

        if (widthPercent != null)
            this.percentWidth = widthPercent;

        this.disabled = !initiallyEnabled;

        if (onPress != null)
            this.onClick = _ -> onPress();
    }

    private function get_enabled():Bool
    {
        return !this.disabled;
    }

    private function set_enabled(value:Bool):Bool
    {
        this.disabled = !value;
        return value;
    }

    private function set_primary(value:Bool):Bool
    {
        primary = value;

        if (value)
        {
            this.addClass("haxefolio-action-button-primary");

            if (AppearanceContext.current.actionEmphasis == Outlined)
                this.addClass("haxefolio-action-button-outlined");
        }
        else
        {
            this.removeClass("haxefolio-action-button-primary");
            this.removeClass("haxefolio-action-button-outlined");
        }

        return value;
    }
}
