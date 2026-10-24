package haxefolio.form;

import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;
import haxefolio.appearance.AppearanceContext;
import haxefolio.form.plumbing.AutofillNeutralTextField;
import haxefolio.form.plumbing.FieldActionButton;
import haxefolio.form.plumbing.FieldHeader;
import haxefolio.form.plumbing.HintState;
import haxefolio.form.plumbing.PasswordRevealButton;
import js.Browser;
import js.html.Element;
import js.html.Event;
import js.html.InputElement;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import morestd.Detachable;

/*
    A labelled text input validated live by its host: a FieldHeader whose right-hand hint is the
    field's single message slot (the constraint while fine, the error while not - theme rules 1 and 2
    of validation), over a full-width input `fieldHeight` tall. The component decides nothing about
    validity: the host reads each edit through `onText` and writes back `hint`, `hintState` and
    `invalid`. That keeps "when does an error show" (on first content, after a submit attempt, ...)
    the host's policy, which differs from form to form.

    Unlike CommitTextField there is no commit: the value is the input's text at any moment. Enter
    calls `onSubmit`, if given - the hook for submitting the surrounding form.

    A RevealablePassword input carries a PasswordRevealButton in a square lane at its right edge, as
    tall as the input; the input's right padding is that lane, so text never runs under the glyph.
    Caps Lock is reported the same way as text, through `onCapsLockChange`, and what to say about it
    is again the host's call.

    `setPrefix` draws a fixed, non-editable text at the input's left edge (a unit, a namespace like
    "Guest"), the input's left padding reserving its lane so typed text never runs under it;
    `setSuffix` does the same at the right edge.

    `setAction` puts a glyph button in the same lane as the reveal toggle (so not on a
    RevealablePassword field): the hook for a helper like a picker that fills the field.
*/
class TextInputField extends VBox
{
    private final header:FieldHeader;
    private final inputBox:Box;
    private final input:TextField;
    private var prefixLabel:Null<Label> = null;
    private var suffixLabel:Null<Label> = null;
    private var placeholderLabel:Null<Label> = null;
    private final onTextChange:String->Void;
    private final heightBinding:Detachable;
    private final revealButton:Null<PasswordRevealButton>;
    private var actionButton:Null<FieldActionButton> = null;
    private var renderedText:String = "";

    /**
        Reading returns what the input currently holds. Assigning renders the text without calling
        `onText` (the assigner already knows).
    **/
    public var currentText(get, set):String;

    /**
        The header's right-hand message; `null` or empty leaves the slot blank (it keeps its height).
    **/
    public var hint(get, set):Null<String>;

    /**
        `Error` colours the hint `danger`; `Normal`/`Muted` read as `inkMuted`.
    **/
    public var hintState(get, set):HintState;

    /**
        Whether the input shows the invalid border. It wins over the focus border, so an error stays
        visible while the user corrects it.
    **/
    public var invalid(default, set):Bool = false;

    /**
        A disabled field greys out in place (input and label) and cannot be typed into.
    **/
    public var enabled(default, set):Bool;

    /**
        Whether the input currently holds keyboard focus.
    **/
    public var focused(get, never):Bool;

    /**
        Whether Caps Lock is on while the input is focused - always `false` while it is not. Browsers
        only report the lock state with a key or pointer event, so it becomes known on the first key
        press (or click) in the input, not on focus alone.
    **/
    public var capsLockOn(default, null):Bool = false;

    /**
        Called whenever `capsLockOn` changes.
    **/
    public var onCapsLockChange:Null<Bool->Void> = null;

    /**
        Whether focusing the input selects its whole text, so a paste replaces the previous value.
    **/
    public var selectAllOnFocus:Bool = false;

    /**
        Shown in the input while it is empty, interpreted like any HaxeUI `.text` property. Drawn as a
        label over the input, since HaxeUI's own placeholder is written into the input's value.
    **/
    public var placeholder(get, set):Null<String>;

    /**
        `maxChars` caps what can be typed (`null` for no cap); `mode` says whether the input is
        obscured and whether it can be revealed.
    **/
    public function new(label:String, onText:String->Void, ?onSubmit:Void->Void, mode:TextInputMode = Plain, ?maxChars:Int, enabled:Bool = true)
    {
        super();

        this.percentWidth = 100;
        this.verticalSpacing = 0; // FieldHeader's own margin-bottom is the only gap
        this.addClass("haxefolio-text-input-field");
        this.onTextChange = onText;

        // the header row is the field's message slot, so it is exactly one message line tall (validation rule 1)
        header = new FieldHeader(label);
        header.height = AppearanceContext.current.geometry.messageLine;
        this.addComponent(header);

        // the input and the reveal lane share one box, the lane drawn over the input's right edge
        inputBox = new Box();
        inputBox.percentWidth = 100;
        this.addComponent(inputBox);

        input = new AutofillNeutralTextField();
        input.percentWidth = 100;
        input.password = mode != Plain;
        input.addClass("haxefolio-text-input");
        if (maxChars != null)
            input.maxChars = maxChars;
        input.onChange = onInputChanged;
        inputBox.addComponent(input);

        if (mode == RevealablePassword)
        {
            revealButton = new PasswordRevealButton(revealed -> input.password = !revealed);
            revealButton.horizontalAlign = "right";
            revealButton.verticalAlign = "center";
            inputBox.addComponent(revealButton);
        }
        else
            revealButton = null;

        if (onSubmit != null)
            input.registerEvent(UIEvent.SUBMIT, _ -> onSubmit());

        // HaxeUI's own :active (focused) state is driven by the FocusManager, which HaxeFolio disables
        input.element.addEventListener("focusin", () -> input.addClass("haxefolio-text-input-focused"));
        input.element.addEventListener("focusout", () -> input.removeClass("haxefolio-text-input-focused"));
        input.element.addEventListener("focusin", selectAllIfRequested);

        input.element.addEventListener("keydown", updateCapsLock);
        input.element.addEventListener("keyup", updateCapsLock);
        input.element.addEventListener("mousedown", updateCapsLock);
        input.element.addEventListener("focusout", () -> setCapsLockOn(false));

        heightBinding = ResponsivityController.bind(AppearanceContext.current.geometry.fieldHeight, applyFieldHeight);

        this.enabled = enabled;
    }

    /**
        Detaches the breakpoint subscription for the input's height - call once the field is removed
        for good. A no-op unless `fieldHeight` differs between the two breakpoint states.
    **/
    public function dispose():Void
    {
        heightBinding.detach();
    }

    /**
        Moves keyboard focus into the input. Goes to the native element directly, since HaxeFolio
        disables HaxeUI's FocusManager; the field must already be on screen. Works right after
        re-enabling the field.
    **/
    public function focus():Void
    {
        var native:Null<Element> = nativeInput();

        if (native == null)
            return;

        /*
            The backend lifts the native `disabled` only on the next validation, and a disabled input
            ignores focus(), so a just-re-enabled field is validated now. Only then: validateNow()
            while the field's container still awaits its first layout loses the layout's move of
            the input (it stays drawn at top 0, over the header).
        */
        if ((cast native : InputElement).disabled && !input.disabled)
            input.validateNow();

        (cast native : Dynamic).focus({preventScroll: true});
    }

    /**
        Shows `text` inside the input at its left edge, the input's left padding set to `laneWidth`
        so typed text starts past it. The lane is not measured: give it room for the widest
        translation. `null` removes the prefix and restores the padding.
    **/
    public function setPrefix(text:Null<String>, laneWidth:Int = 0):Void
    {
        if (text == null)
        {
            if (prefixLabel != null)
            {
                inputBox.removeComponent(prefixLabel);
                prefixLabel = null;
                input.paddingLeft = null;
            }
            return;
        }

        if (prefixLabel == null)
        {
            prefixLabel = new Label();
            prefixLabel.verticalAlign = "center";
            prefixLabel.addClass("haxefolio-text-input-prefix");
            prefixLabel.element.style.pointerEvents = "none"; // a click on it lands on the input
            inputBox.addComponent(prefixLabel);
        }

        prefixLabel.text = text;
        input.paddingLeft = laneWidth;
    }

    /**
        Shows `text` inside the input at its right edge (a unit), the input's right padding set to
        `laneWidth` so typed text ends before it. The lane is not measured: give it room for the
        widest translation. `null` removes the suffix and restores the padding. Not for a
        `RevealablePassword` field, whose right edge is the reveal toggle's.
    **/
    public function setSuffix(text:Null<String>, laneWidth:Int = 0):Void
    {
        if (text == null)
        {
            if (suffixLabel != null)
            {
                inputBox.removeComponent(suffixLabel);
                suffixLabel = null;
                input.paddingRight = null;
            }
            return;
        }

        if (suffixLabel == null)
        {
            suffixLabel = new Label();
            suffixLabel.horizontalAlign = "right";
            suffixLabel.verticalAlign = "center";
            suffixLabel.addClass("haxefolio-text-input-suffix");
            suffixLabel.element.style.pointerEvents = "none"; // a click on it lands on the input
            inputBox.addComponent(suffixLabel);
        }

        suffixLabel.text = text;
        input.paddingRight = laneWidth;
    }

    /**
        Shows a square button at the input's right edge, drawing `glyphPaths` (markup in a 16x16
        viewBox, stroked in the text colour), named `label` for assistive technology; the input's
        right padding is its lane. `onActivate` runs on a click while the field is enabled.
    **/
    public function setAction(glyphPaths:String, label:String, onActivate:Void->Void):Void
    {
        if (actionButton != null)
            inputBox.removeComponent(actionButton);

        actionButton = new FieldActionButton(glyphPaths, label, onActivate);
        actionButton.horizontalAlign = "right";
        actionButton.verticalAlign = "center";
        actionButton.disabled = !enabled;
        inputBox.addComponent(actionButton);
        applyFieldHeight(Std.int(input.height));
    }

    /**
        Whether touch devices bring up a numeric keyboard for the input (`inputmode="numeric"`). It
        only changes the keyboard: what may be typed is still the host's to validate.
    **/
    public function setNumericKeyboard(numeric:Bool):Void
    {
        var native:Null<Element> = nativeInput();

        if (native == null)
            return;

        if (numeric)
            native.setAttribute("inputmode", "numeric");
        else
            native.removeAttribute("inputmode");
    }

    private function applyFieldHeight(height:Int):Void
    {
        input.height = height;

        if (actionButton != null)
        {
            actionButton.width = height;
            actionButton.height = height;
            input.paddingRight = height;
        }

        if (revealButton == null)
            return;

        revealButton.width = height;
        revealButton.height = height;
        input.paddingRight = height;
    }

    // browser autofill dispatches plain `Event`s under these names, which carry no modifier state
    private function updateCapsLock(event:Event):Void
    {
        if (Std.isOfType(event, KeyboardEvent))
            setCapsLockOn((cast event : KeyboardEvent).getModifierState("CapsLock"));
        else if (Std.isOfType(event, MouseEvent))
            setCapsLockOn((cast event : MouseEvent).getModifierState("CapsLock"));
    }

    private function setCapsLockOn(value:Bool):Void
    {
        if (value == capsLockOn)
            return;

        capsLockOn = value;

        if (onCapsLockChange != null)
            onCapsLockChange(value);
    }

    // deferred, as the click that focused the input would otherwise collapse the selection on mouseup
    private function selectAllIfRequested():Void
    {
        if (!selectAllOnFocus)
            return;

        Browser.window.setTimeout(() -> {
            var native:Null<Element> = nativeInput();

            if (native != null && focused)
                (cast native : InputElement).select();
        }, 0);
    }

    private function nativeInput():Null<Element>
    {
        var root:Element = input.element;
        return root.tagName == "INPUT" ? root : root.querySelector("input");
    }

    private function get_focused():Bool
    {
        var native:Null<Element> = nativeInput();
        return native != null && Browser.document.activeElement == native;
    }

    private function get_currentText():String
    {
        return input.text ?? "";
    }

    private function set_currentText(value:String):String
    {
        renderedText = value;
        input.text = value;
        var native:Null<Element> = nativeInput();
        if (native != null)
            (cast native : InputElement).value = value; // HaxeUI writes it only on its next validation, which typing can overtake
        refreshPlaceholder();
        return value;
    }

    private function get_placeholder():Null<String>
    {
        return placeholderLabel != null ? placeholderLabel.text : null;
    }

    private function set_placeholder(value:Null<String>):Null<String>
    {
        if (value == null)
        {
            if (placeholderLabel != null)
            {
                inputBox.removeComponent(placeholderLabel);
                placeholderLabel = null;
            }
            return value;
        }

        if (placeholderLabel == null)
        {
            placeholderLabel = new Label();
            placeholderLabel.verticalAlign = "center";
            placeholderLabel.addClass("haxefolio-text-input-placeholder");
            placeholderLabel.element.style.pointerEvents = "none"; // a click on it lands on the input
            inputBox.addComponent(placeholderLabel);
        }

        placeholderLabel.text = value;
        refreshPlaceholder();
        return value;
    }

    private function refreshPlaceholder():Void
    {
        if (placeholderLabel != null)
            placeholderLabel.hidden = currentText.length > 0;
    }

    private function get_hint():Null<String>
    {
        return header.hint;
    }

    private function set_hint(value:Null<String>):Null<String>
    {
        header.hint = value;
        return value;
    }

    private function get_hintState():HintState
    {
        return header.state;
    }

    private function set_hintState(value:HintState):HintState
    {
        header.state = value;
        return value;
    }

    private function set_invalid(value:Bool):Bool
    {
        invalid = value;

        if (value)
            input.addClass("haxefolio-text-input-invalid");
        else
            input.removeClass("haxefolio-text-input-invalid");

        return value;
    }

    private function set_enabled(value:Bool):Bool
    {
        enabled = value;
        input.disabled = !value;
        header.locked = !value;
        if (revealButton != null)
            revealButton.disabled = !value;
        if (actionButton != null)
            actionButton.disabled = !value;
        return value;
    }

    /*
        As in CommitTextField: a programmatic assignment makes HaxeUI dispatch CHANGE asynchronously,
        so only a genuine user edit makes the input's text differ from what was last rendered.
    */
    private function onInputChanged(_:UIEvent):Void
    {
        var current:String = currentText;

        if (current == renderedText)
            return;

        renderedText = current;
        refreshPlaceholder();
        onTextChange(current);
    }
}
