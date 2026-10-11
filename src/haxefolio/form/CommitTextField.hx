package haxefolio.form;

import haxe.ui.components.Button;
import haxe.ui.components.TextField;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;
import haxefolio.appearance.AppearanceContext;
import haxefolio.form.plumbing.AutofillNeutralTextField;
import haxefolio.form.plumbing.CommitResult;
import haxefolio.form.plumbing.CommitTrigger;
import haxefolio.form.plumbing.FieldHeader;
import haxefolio.form.plumbing.HintLine;

private enum CommitFieldState
{
    Idle;
    Pending;
    Applied;
    Rejected(message:String);
}

/*
    A text input whose value applies on an explicit action, for inputs too expensive or too
    error-prone to validate per keystroke. Its HintLine cycles through the idle instruction, the
    success confirmation and the rejection reason - and that line is why the component exists: a
    commit button with silent failure is worse than live validation.

    Any edit returns the line to the idle instruction (the applied/rejected message described a
    value the field no longer holds). `onCommit` returns a CommitResult rather than throwing, so
    a host's validator stays a pure function.

    Given a `pendingHint`, the field also tells an edit that has not been applied yet: while the
    text differs from the last applied (or assigned) one, the line shows `pendingHint` and the
    input a pending border, and the commit button is enabled only then - there is nothing to apply
    otherwise, nor after a rejection until the next edit.

    Blur is deliberately not a commit trigger: HaxeFolio disables HaxeUI's FocusManager, so no
    focus-out event is delivered, and a blur-commit would in any case fire before the click on
    the commit button and commit twice.

    The commit button flexes the other way round from the input: the input takes whatever width
    the button leaves (the same direction Stepper uses). A `null` label leaves the header out.
*/
class CommitTextField extends VBox
{
    private final input:TextField;
    private final commitButton:Button;
    private final header:Null<FieldHeader>;
    private final hintLine:HintLine;
    private final onTextChange:String->Void;
    private final onCommit:String->CommitResult;
    private final appliedHint:String;
    private final pendingHint:Null<String>;
    private var renderedText:String = "";
    private var appliedText:String = "";
    private var state:CommitFieldState = Idle;

    /**
        Reading returns what the input currently holds. Assigning renders the text as applied
        without calling `onText` (the assigner already knows) and returns the hint line to the idle
        instruction.
    **/
    public var currentText(get, set):String;

    /** The instruction shown while there is nothing else to say **/
    public var idleHint(default, set):String;

    public var enabled(default, set):Bool;

    public function new(
        label:Null<String>,
        initialText:String,
        onText:String->Void,
        onCommit:String->CommitResult,
        commitLabel:String,
        idleHint:String,
        appliedHint:String,
        commitTrigger:CommitTrigger = ButtonAndEnter,
        enabled:Bool = true,
        ?pendingHint:String
    )
    {
        super();

        this.percentWidth = 100;
        this.verticalSpacing = 0; // FieldHeader's own margin-bottom and the hint line's margin-top are the only gaps
        this.addClass("haxefolio-commit-text-field");
        this.onTextChange = onText;
        this.onCommit = onCommit;
        this.appliedHint = appliedHint;
        this.pendingHint = pendingHint;

        if (label != null)
        {
            header = new FieldHeader(label);
            this.addComponent(header);
        }
        else
            header = null;

        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.horizontalSpacing = 6;
        this.addComponent(row);

        input = new AutofillNeutralTextField();
        input.percentWidth = 100;
        input.addClass("haxefolio-commit-input");
        input.onChange = onInputChanged;
        row.addComponent(input);

        commitButton = new Button();
        commitButton.text = commitLabel;
        commitButton.addClass("haxefolio-commit-button");

        if (AppearanceContext.current.actionEmphasis == Outlined)
            commitButton.addClass("haxefolio-commit-button-outlined");

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

        this.idleHint = idleHint;
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
        appliedText = value;
        input.text = value;
        setState(Idle);
        return value;
    }

    private function set_idleHint(value:String):String
    {
        idleHint = value;
        render();
        return value;
    }

    private function set_enabled(value:Bool):Bool
    {
        enabled = value;
        input.disabled = !value;

        if (header != null)
            header.locked = !value;

        render();
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
        setState(pendingHint != null && current != appliedText ? Pending : Idle);
        onTextChange(current);
    }

    private function commit():Void
    {
        if (!enabled || (pendingHint != null && state != Pending))
            return;

        var text:String = currentText;

        switch onCommit(text)
        {
            case Applied:
                appliedText = text;
                setState(Applied);
            case Rejected(message):
                setState(Rejected(message));
        }
    }

    private function setState(value:CommitFieldState):Void
    {
        state = value;
        render();
    }

    private function render():Void
    {
        input.removeClass("haxefolio-commit-input-invalid");
        input.removeClass("haxefolio-commit-input-pending");
        hintLine.state = Normal;

        switch state
        {
            case Idle:
                hintLine.text = idleHint;
            case Pending:
                hintLine.text = pendingHint;
                input.addClass("haxefolio-commit-input-pending");
            case Applied:
                hintLine.text = appliedHint;
            case Rejected(message):
                hintLine.text = message;
                hintLine.state = Error;
                input.addClass("haxefolio-commit-input-invalid");
        }

        commitButton.disabled = !enabled || (pendingHint != null && state != Pending);
    }
}
