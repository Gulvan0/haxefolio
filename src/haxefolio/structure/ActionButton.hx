package haxefolio.structure;

import haxe.ui.components.Button;
import haxefolio.appearance.AppearanceContext;

/*
    One button of an ActionBar. Either an ordinary action (the unselected ChoiceButton look) or the
    primary one, drawn per the app's EmphasisStyle - read from AppearanceContext when built, like
    the other emphasised components, so it agrees with them.

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
        `widthPercent` is the button's share of its bar's width; leave it out to split whatever
        the bar's other buttons leave evenly (see `ActionBar`).
    **/
    public function new(caption:String, onPress:Void->Void, primary:Bool = false, ?glyph:String, ?widthPercent:Float, initiallyEnabled:Bool = true)
    {
        super();

        this.text = caption;
        this.addClass("haxefolio-action-button");

        if (primary)
        {
            this.addClass("haxefolio-action-button-primary");

            if (AppearanceContext.current.emphasis == Outlined)
                this.addClass("haxefolio-action-button-outlined");
        }

        if (glyph != null)
            this.icon = glyph;

        if (widthPercent != null)
            this.percentWidth = widthPercent;

        this.disabled = !initiallyEnabled;
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
}
