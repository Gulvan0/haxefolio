package haxefolio.form.plumbing;

import haxe.ui.components.Label;
import haxe.ui.containers.HBox;

/*
    A label on the left, an optional hint on the right, on one baseline-aligned row.
    `.haxefolio-field-header`'s `justify-content: space-between` (main.css) does the
    left/right split; both children are `verticalAlign = "center"` for the baseline
    alignment.
*/
class FieldHeader extends HBox
{
    private final labelText:Label;
    private final hintText:Label;

    public var label(default, set):String;
    public var hint(default, set):Null<String>;
    public var state(default, set):HintState;
    public var locked(default, set):Bool;

    public function new(label:String, ?hint:String, state:HintState = Normal, locked:Bool = false)
    {
        super();

        this.percentWidth = 100;
        this.addClass("haxefolio-field-header");

        labelText = new Label();
        labelText.verticalAlign = "center";
        labelText.addClass("haxefolio-field-header-label");
        this.addComponent(labelText);

        hintText = new Label();
        hintText.verticalAlign = "center";
        hintText.addClass("haxefolio-field-header-hint");
        this.addComponent(hintText);

        this.label = label;
        this.hint = hint;
        this.state = state;
        this.locked = locked;
    }

    private function set_label(value:String):String
    {
        label = value;
        labelText.text = value;
        return value;
    }

    private function set_hint(value:Null<String>):Null<String>
    {
        hint = value;
        hintText.text = value == null? "" : value;
        return value;
    }

    private function set_state(value:HintState):HintState
    {
        state = value;

        if (value == Error)
            hintText.addClass("haxefolio-field-header-hint-error");
        else
            hintText.removeClass("haxefolio-field-header-hint-error");

        return value;
    }

    private function set_locked(value:Bool):Bool
    {
        locked = value;

        if (value)
            labelText.addClass("haxefolio-field-header-label-locked");
        else
            labelText.removeClass("haxefolio-field-header-label-locked");

        return value;
    }
}
