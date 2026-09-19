package haxefolio.form;

import haxe.ui.components.Button;
import haxe.ui.components.TextField;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;
import haxefolio.form.plumbing.CommitResult;
import haxefolio.form.plumbing.CommitTrigger;
import haxefolio.form.plumbing.FieldHeader;
import haxefolio.form.plumbing.HintLine;

/*
    A text input whose value applies on an explicit action, for inputs too expensive or too
    error-prone to validate per keystroke. Its HintLine cycles through three messages - the
    idle instruction, the success confirmation and the rejection reason - and that line is why
    the component exists: a commit button with silent failure is worse than live validation.

    Any edit returns the line to the idle instruction (the applied/rejected message described a
    value the field no longer holds). `onCommit` returns a CommitResult rather than throwing, so
    a host's validator stays a pure function.

    Blur is deliberately not a commit trigger: HaxeFolio disables HaxeUI's FocusManager, so no
    focus-out event is delivered, and a blur-commit would in any case fire before the click on
    the commit button and commit twice.

    The commit button flexes the other way round from the input: the input takes whatever width
    the button leaves (the same direction Stepper uses).
*/
class CommitTextField extends VBox
{
    private final input:TextField;
    private final commitButton:Button;
    private final header:FieldHeader;
    private final hintLine:HintLine;
    private final onTextChange:String->Void;
    private final onCommit:String->CommitResult;
    private final idleHint:String;
    private final appliedHint:String;
    private var renderedText:String = "";

    /**
        Reading returns what the input currently holds. Assigning renders the text without
        calling `onText` (the assigner already knows) and returns the hint line to the idle
        instruction.
    **/
    public var currentText(get, set):String;

    public var enabled(default, set):Bool;

    public function new(
        label:String,
        initialText:String,
        onText:String->Void,
        onCommit:String->CommitResult,
        commitLabel:String,
        idleHint:String,
        appliedHint:String,
        commitTrigger:CommitTrigger = ButtonAndEnter,
        enabled:Bool = true
    )
    {
        super();

        this.percentWidth = 100;
        this.verticalSpacing = 0; // FieldHeader's own margin-bottom and the hint line's margin-top are the only gaps
        this.addClass("haxefolio-commit-text-field");
        this.onTextChange = onText;
        this.onCommit = onCommit;
        this.idleHint = idleHint;
        this.appliedHint = appliedHint;

        header = new FieldHeader(label);
        this.addComponent(header);

        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.horizontalSpacing = 6;
        this.addComponent(row);

        input = new TextField();
        input.percentWidth = 100;
        input.addClass("haxefolio-commit-input");
        input.onChange = onInputChanged;
        row.addComponent(input);

        commitButton = new Button();
        commitButton.text = commitLabel;
        commitButton.addClass("haxefolio-commit-button");
        row.addComponent(commitButton);

        if (commitTrigger == Enter)
            commitButton.hidden = true;
        else
            commitButton.onClick = _ -> commit();

        if (commitTrigger != Button)
            input.registerEvent(UIEvent.SUBMIT, _ -> commit());

        hintLine = new HintLine(idleHint);
        hintLine.addClass("haxefolio-commit-hint");
        this.addComponent(hintLine);

        this.currentText = initialText;
        this.enabled = enabled;
    }

    private function get_currentText():String
    {
        return input.text ?? "";
    }

    private function set_currentText(value:String):String
    {
        renderedText = value;
        input.text = value;
        showIdle();
        return value;
    }

    private function set_enabled(value:Bool):Bool
    {
        enabled = value;
        input.disabled = !value;
        commitButton.disabled = !value;
        header.locked = !value;
        return value;
    }

    /*
        Setting the text programmatically makes HaxeUI dispatch a CHANGE event too, but
        asynchronously, so a re-entrancy flag around the assignment would not catch it. Comparing
        against what this component last rendered/reported does: only a genuine user edit ever
        makes the input's text differ from it.
    */
    private function onInputChanged(_:UIEvent):Void
    {
        var current:String = currentText;

        if (current == renderedText)
            return;

        renderedText = current;
        showIdle();
        onTextChange(current);
    }

    private function commit():Void
    {
        switch onCommit(currentText)
        {
            case Applied:
                input.removeClass("haxefolio-commit-input-invalid");
                hintLine.text = appliedHint;
                hintLine.state = Normal;
            case Rejected(message):
                input.addClass("haxefolio-commit-input-invalid");
                hintLine.text = message;
                hintLine.state = Error;
        }
    }

    private function showIdle():Void
    {
        input.removeClass("haxefolio-commit-input-invalid");
        hintLine.text = idleHint;
        hintLine.state = Normal;
    }
}
