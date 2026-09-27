package haxefolio.form;

import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;
import haxefolio.appearance.AppearanceContext;
import haxefolio.form.plumbing.AutofillNeutralTextField;
import haxefolio.form.plumbing.FieldHeader;
import haxefolio.form.plumbing.HintState;
import haxefolio.form.plumbing.PasswordRevealButton;
import js.Browser;
import js.html.Element;
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
*/
class TextInputField extends VBox
{
    private final header:FieldHeader;
    private final input:TextField;
    private final onTextChange:String->Void;
    private final heightBinding:Detachable;
    private final revealButton:Null<PasswordRevealButton>;
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
        var inputBox:Box = new Box();
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

        input.element.addEventListener("keydown", (event:KeyboardEvent) -> setCapsLockOn(event.getModifierState("CapsLock")));
        input.element.addEventListener("keyup", (event:KeyboardEvent) -> setCapsLockOn(event.getModifierState("CapsLock")));
        input.element.addEventListener("mousedown", (event:MouseEvent) -> setCapsLockOn(event.getModifierState("CapsLock")));
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

    private function applyFieldHeight(height:Int):Void
    {
        input.height = height;

        if (revealButton == null)
            return;

        revealButton.width = height;
        revealButton.height = height;
        input.paddingRight = height;
    }

    private function setCapsLockOn(value:Bool):Void
    {
        if (value == capsLockOn)
            return;

        capsLockOn = value;

        if (onCapsLockChange != null)
            onCapsLockChange(value);
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
        return value;
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
        onTextChange(current);
    }
}
