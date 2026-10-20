package haxefolio.form;

import haxe.Timer;
import haxe.ui.components.TextArea;
import haxe.ui.components.TextField;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.appearance.AppearanceContext;
import haxefolio.browser.Clipboard;
import haxefolio.form.plumbing.FieldHeader;
import haxefolio.structure.ActionButton;
import js.Browser;
import js.html.Element;
import js.html.InputElement;
import js.html.TextAreaElement;
import morestd.Detachable;

/*
    A value to be copied rather than edited: a FieldHeader over a read-only input and, beside it, a
    Copy button. The input selects its whole text on focus. Copying relabels the button for
    `COPIED_MS`; the button has a fixed width, so the relabel moves nothing. When the Clipboard API
    refuses (no permission, an insecure origin), the input's text is selected and copied with
    `execCommand("copy")` instead.

    A multiline field is a fixed-height box that scrolls inside, the button aligned to its top.
*/
class CopyField extends VBox
{
    private static inline final COPIED_MS:Int = 1600;

    private final input:Component;
    private final button:ActionButton;
    private final heightBinding:Detachable;
    private var resetTimer:Null<Timer> = null;

    /** What is shown and copied **/
    public var copiedText(default, set):String;

    /**
        `multilineHeight`, if given, makes the field a multiline box of that height. The button is
        `buttonWidth` wide: give it room for the longer of the two labels in every locale.
    **/
    public function new(label:String, value:String, buttonWidth:Int, ?multilineHeight:Int)
    {
        super();

        this.percentWidth = 100;
        this.verticalSpacing = 0; // FieldHeader's own margin-bottom is the only gap
        this.addClass("haxefolio-copy-field");

        var header:FieldHeader = new FieldHeader(label);
        header.height = AppearanceContext.current.geometry.messageLine;
        this.addComponent(header);

        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.addClass("haxefolio-copy-field-row");
        this.addComponent(row);

        if (multilineHeight != null)
        {
            var area:TextArea = new TextArea();
            area.height = multilineHeight;
            area.addClass("haxefolio-copy-field-area");
            input = area;
        }
        else
        {
            var field:TextField = new TextField();
            field.addClass("haxefolio-copy-field-input");
            input = field;
        }
        input.percentWidth = 100;
        input.addClass("haxefolio-text-input");
        row.addComponent(input);

        button = new ActionButton(copyLabel(), copy);
        button.width = buttonWidth;
        button.verticalAlign = "top";
        row.addComponent(button);

        heightBinding = ResponsivityController.bind(AppearanceContext.current.geometry.fieldHeight, height -> {
            button.height = height;
            if (multilineHeight == null)
                input.height = height;
        });

        var native:Element = nativeInput();
        native.setAttribute("readonly", "readonly");
        native.addEventListener("focus", selectAll);
        native.addEventListener("focusin", () -> input.addClass("haxefolio-text-input-focused"));
        native.addEventListener("focusout", () -> input.removeClass("haxefolio-text-input-focused"));

        this.copiedText = value;
    }

    /**
        Stops the pending relabel and detaches the breakpoint subscription - call once the field is
        removed for good.
    **/
    public function dispose():Void
    {
        stopResetTimer();
        heightBinding.detach();
    }

    private function copy():Void
    {
        // without a secure origin there is no `navigator.clipboard` at all
        try
        {
            Clipboard.copy(copiedText, onCopied, _ -> copyBySelection());
        }
        catch (_)
        {
            copyBySelection();
        }
    }

    private function copyBySelection():Void
    {
        selectAll();

        var copied:Bool = try Browser.document.execCommand("copy") catch (_) false;
        if (copied)
            onCopied();
    }

    private function onCopied():Void
    {
        stopResetTimer();
        button.text = LocaleUtils.localeBinding("haxefolio.copy_field.copied");
        resetTimer = Timer.delay(() -> {
            resetTimer = null;
            button.text = copyLabel();
        }, COPIED_MS);
    }

    private function stopResetTimer():Void
    {
        if (resetTimer != null)
            resetTimer.stop();
        resetTimer = null;
    }

    private function selectAll():Void
    {
        var native:Element = nativeInput();

        if (native.tagName == "TEXTAREA")
            (cast native : TextAreaElement).select();
        else
            (cast native : InputElement).select();
    }

    private function nativeInput():Element
    {
        var root:Element = input.element;
        return root.tagName == "INPUT" || root.tagName == "TEXTAREA" ? root : root.querySelector("input, textarea");
    }

    private static function copyLabel():String
    {
        return LocaleUtils.localeBinding("haxefolio.copy_field.copy");
    }

    private function set_copiedText(value:String):String
    {
        copiedText = value;
        input.text = value;
        return value;
    }
}
