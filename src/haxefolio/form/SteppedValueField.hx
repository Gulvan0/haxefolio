package haxefolio.form;

import haxe.ui.containers.VBox;
import haxefolio.form.plumbing.FieldHeader;
import haxefolio.form.plumbing.FieldState;
import haxefolio.form.plumbing.Stepper;

/*
    A Stepper under a FieldHeader, generic over the value type via a `parse`/`format` pair. The
    header's right-aligned hint carries the constraint ("max 6:00:00") while the field is valid
    and swaps to the failure reason, in red, when it is not - the same reserved line either way,
    so validation appearing is a colour change rather than a layout change.

    Invalid input is never reverted or clamped: the user's keystrokes are theirs. The field marks
    itself, reports the change in validity upward (`onValidityChange`, `valid`, `state`) and keeps
    `onChange` reserved for values that parsed *and* validated, so a host holding the last
    `onChange` value never holds an invalid one. Errors only show once the field has been touched
    (edited or stepped by the user): a field that starts out invalid opens showing only its
    neutral hint.

    `validate` returns a whole FieldState for the signature's sake, but only its `valid` and
    `message` matter: the field overwrites `value` and `touched` itself, and `message` is used
    only while the field is invalid (while valid, the constructor's `hint` is shown instead). No
    `text-overflow: ellipsis` exists, so a message must fit the header's line by construction -
    at a 288px half-width column roughly 22 label characters plus 14 hint/message characters.

    `step` is applied to the last known value on each -/+ press and is expected to keep its
    result within bounds itself: a button press has no "unparseable" case, so clamping there is
    unsurprising in a way clamping typed text would not be.
*/
class SteppedValueField<T> extends VBox
{
    private final header:FieldHeader;
    private final stepper:Stepper;
    private final onValueChange:T->Void;
    private final parse:String->Null<T>;
    private final format:T->String;
    private final step:T->Int->T;
    private final validate:T->FieldState<T>;
    private final hint:String;
    private final invalidFormatMessage:String;
    private final onValidityChange:Null<Bool->Void>;

    /**
        The last known value (the last one that parsed - which may have failed `validate`) with
        its validity, message and touched flag. Read-only from outside; use `currentValue` to assign.
    **/
    public var state(default, null):FieldState<T>;

    /**
        Reading returns `state.value`. Assigning renders and re-validates the new value without
        calling `onChange` (the assigner already knows it) but does call `onValidityChange` if
        validity flips - the hook for "presets plus custom" bindings where a neighbouring
        control (e.g. a preset grid) drives this field.
    **/
    public var currentValue(get, set):T;

    public var valid(get, never):Bool;
    public var enabled(default, set):Bool;

    public function new(
        label:String,
        value:T,
        onChange:T->Void,
        parse:String->Null<T>,
        format:T->String,
        step:T->Int->T,
        validate:T->FieldState<T>,
        hint:String,
        invalidFormatMessage:String,
        enabled:Bool = true,
        ?onValidityChange:Bool->Void
    )
    {
        super();

        this.percentWidth = 100;
        this.verticalSpacing = 0; // FieldHeader's own margin-bottom is this field's only header-to-stepper gap
        this.addClass("haxefolio-stepped-value-field");
        this.onValueChange = onChange;
        this.parse = parse;
        this.format = format;
        this.step = step;
        this.validate = validate;
        this.hint = hint;
        this.invalidFormatMessage = invalidFormatMessage;
        this.onValidityChange = onValidityChange;

        header = new FieldHeader(label, hint);
        this.addComponent(header);

        stepper = new Stepper(format(value), onText, onStep);
        this.addComponent(stepper);

        var initial:FieldState<T> = validate(value);
        state = {value: value, valid: initial.valid, message: initial.message, touched: false};
        render();

        this.enabled = enabled;
    }

    private function get_currentValue():T
    {
        return state.value;
    }

    private function set_currentValue(newValue:T):T
    {
        stepper.displayedText = format(newValue);
        applyValue(newValue, state.touched);
        return newValue;
    }

    private function get_valid():Bool
    {
        return state.valid;
    }

    private function set_enabled(value:Bool):Bool
    {
        enabled = value;
        stepper.enabled = value;
        header.locked = !value;
        return value;
    }

    private function onText(text:String):Void
    {
        var parsed:Null<T> = parse(text);

        if (parsed == null)
        {
            applyState({value: state.value, valid: false, message: invalidFormatMessage, touched: true});
            return;
        }

        commitParsed(parsed);
    }

    private function onStep(direction:Int):Void
    {
        var stepped:T = step(state.value, direction);
        stepper.displayedText = format(stepped);
        commitParsed(stepped);
    }

    private function commitParsed(parsed:T):Void
    {
        applyValue(parsed, true);

        if (state.valid)
            onValueChange(parsed);
    }

    private function applyValue(newValue:T, touched:Bool):Void
    {
        var validated:FieldState<T> = validate(newValue);
        applyState({value: newValue, valid: validated.valid, message: validated.message, touched: touched});
    }

    private function applyState(newState:FieldState<T>):Void
    {
        var wasValid:Bool = state.valid;
        state = newState;
        render();

        if (wasValid != newState.valid && onValidityChange != null)
            onValidityChange(newState.valid);
    }

    private function render():Void
    {
        var showError:Bool = !state.valid && state.touched;
        header.hint = showError ? state.message : hint;
        header.state = showError ? Error : Normal;
        stepper.invalid = showError;
    }
}
