package haxefolio.form;

import haxefolio.form.plumbing.ChoiceButton;

/*
    A boolean as one full-width button that reads as a mode rather than a checkbox - for when "off"
    is the normal state and "on" a distinct mode (e.g. "No time control"). Styled exactly as a
    ChoiceButton (it is one): the selected treatment follows `EmphasisStyle`, and a disabled toggle
    shows the disabled look when off and the muted locked-selected look when on.

    Use a checkbox instead when the boolean is an attribute rather than a mode, and a two-option
    ChoiceRow when both states deserve equal visual weight.
*/
class ToggleButton extends ChoiceButton
{
    /**
        Whether the mode is on. Assigning renders it without calling `onToggle` (the assigner
        already knows) - the hook for a value driven from elsewhere.
    **/
    public var on(get, set):Bool;

    public var enabled(get, set):Bool;

    /*
        Parameter names deliberately differ from ChoiceButton's own: HaxeUI's component macro
        captures each constructor parameter as a `_constructorParam_<name>` field, and redeclaring
        one in a subclass is a compile error.
    */
    public function new(caption:String, onToggle:Bool->Void, ?glyph:String, initiallyOn:Bool = false, initiallyEnabled:Bool = true)
    {
        super(caption, () -> {}, glyph, Leading, initiallyOn, initiallyEnabled);

        this.percentWidth = 100;
        this.onClick = _ -> onToggle(this.selected);
    }

    private function get_on():Bool
    {
        return this.selected;
    }

    private function set_on(value:Bool):Bool
    {
        this.selected = value;
        return value;
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
