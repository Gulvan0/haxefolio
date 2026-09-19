package haxefolio.form.plumbing;

import haxe.ui.components.Button;
import haxe.ui.components.TextField;
import haxe.ui.containers.HBox;
import haxe.ui.events.UIEvent;

/*
    The `-` / value / `+` triple, with no header and no hint. The buttons are fixed width and the
    input flexes (`percentWidth = 100`) - the other way round is what broke the mobile layout in
    the first iteration of the Intellector challenge overlay.

    The stepper owns no value semantics: `displayedText` is whatever the field rendered, `onText` reports
    what the user typed, `onStep` reports -1/+1 presses; parsing, validation and applying the step
    are the owning field's job (see SteppedValueField).
*/
class Stepper extends HBox
{
    private final decrementButton:Button;
    private final incrementButton:Button;
    private final input:TextField;
    private final onText:String->Void;
    private var renderedText:String = "";

    public var displayedText(default, set):String;
    public var invalid(default, set):Bool;
    public var enabled(default, set):Bool;

    public function new(displayedText:String, onText:String->Void, onStep:Int->Void, enabled:Bool = true, invalid:Bool = false, buttonWidth:Int = 26)
    {
        super();

        this.percentWidth = 100;
        this.horizontalSpacing = 4;
        this.addClass("haxefolio-stepper");
        this.onText = onText;

        decrementButton = createButton("−", buttonWidth, () -> onStep(-1));
        this.addComponent(decrementButton);

        input = new TextField();
        input.percentWidth = 100;
        input.addClass("haxefolio-stepper-input");
        input.onChange = onInputChanged;
        this.addComponent(input);

        incrementButton = createButton("+", buttonWidth, () -> onStep(1));
        this.addComponent(incrementButton);

        this.displayedText = displayedText;
        this.invalid = invalid;
        this.enabled = enabled;
    }

    private function createButton(label:String, width:Float, onPress:Void->Void):Button
    {
        var button:Button = new Button();
        button.text = label;
        button.width = width;
        button.addClass("haxefolio-stepper-button");
        button.onClick = _ -> onPress();
        return button;
    }

    /*
        Setting the text programmatically makes HaxeUI dispatch a CHANGE event too, but
        asynchronously, so a re-entrancy flag around the assignment would not catch it. Comparing
        against what this component last rendered/reported does: only a genuine user edit ever
        makes the input's text differ from it.
    */
    private function onInputChanged(_:UIEvent):Void
    {
        var current:String = input.text ?? "";

        if (current == renderedText)
            return;

        renderedText = current;
        onText(current);
    }

    private function set_displayedText(value:String):String
    {
        displayedText = value;
        renderedText = value;
        input.text = value;
        return value;
    }

    private function set_invalid(value:Bool):Bool
    {
        invalid = value;

        if (value)
            input.addClass("haxefolio-stepper-input-invalid");
        else
            input.removeClass("haxefolio-stepper-input-invalid");

        return value;
    }

    private function set_enabled(value:Bool):Bool
    {
        enabled = value;
        decrementButton.disabled = !value;
        incrementButton.disabled = !value;
        input.disabled = !value;
        return value;
    }
}
