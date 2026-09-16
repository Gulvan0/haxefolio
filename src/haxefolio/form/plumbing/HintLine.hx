package haxefolio.form.plumbing;

import haxe.ui.components.Label;

/*
    A fixed-height (16px, via .haxefolio-hint-line in main.css) line of message text that is
    always present, whether or not `text` is empty - keeps a form's layout from jumping when
    a validation message appears or disappears.
*/
class HintLine extends Label
{
    public var state(default, set):HintState;

    public function new(text:String = "", state:HintState = Normal)
    {
        super();

        this.percentWidth = 100;
        addClass("haxefolio-hint-line");

        this.text = text;
        this.state = state;
    }

    private function set_state(value:HintState):HintState
    {
        state = value;

        if (value == Error)
            addClass("haxefolio-hint-line-error");
        else
            removeClass("haxefolio-hint-line-error");

        return value;
    }
}
