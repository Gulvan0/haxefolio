package haxefolio.form;

import haxe.ui.components.TextField;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.events.UIEvent;
import haxefolio.appearance.AppearanceContext;
import haxefolio.form.plumbing.AutofillNeutralTextField;
import haxefolio.form.plumbing.FieldHeader;
import haxefolio.form.plumbing.HintState;
import js.Browser;
import js.html.Element;
import js.html.InputElement;
import morestd.Detachable;

/*
    A colour typed as `#rrggbb` or picked: a FieldHeader (its right-hand hint the field's message
    slot, as in TextInputField) over one input-like box holding the browser's native colour swatch
    and the hex text. Validity is the host's: every edit - typed, or picked with the swatch, which
    writes the picked hex into the text - reaches `onText`, and the host writes back `hint`,
    `hintState` and `invalid`. The swatch shows the text's colour whenever it parses.

    Disabled, the box greys out, the swatch dims and the text gives way to `disabledPlaceholder`;
    the text is kept and comes back on re-enabling. The label stays as it is: a colour stops
    applying because of a neighbouring control the label usually covers too (a "Transparent"
    toggle). Locked, the whole field greys out, label included, but keeps showing the text - for a
    value that applies but can't be changed right now.
*/
class ColorField extends VBox
{
    private static final HEX_PATTERN:EReg = ~/^#[0-9a-fA-F]{6}$/;

    private final header:FieldHeader;
    private final box:HBox;
    private final swatch:Component;
    private final swatchInput:InputElement;
    private final input:TextField;
    private final onTextChange:String->Void;
    private final disabledPlaceholder:String;
    private final heightBinding:Detachable;
    private var typedText:String = "";
    private var renderedText:String = "";

    /**
        Reading returns the text as typed (kept while disabled). Assigning renders it without
        calling `onText`.
    **/
    public var currentText(get, set):String;

    /** The header's right-hand message; `null` or empty leaves the slot blank (it keeps its height) **/
    public var hint(get, set):Null<String>;

    public var hintState(get, set):HintState;

    /** Whether the box shows the invalid border **/
    public var invalid(default, set):Bool = false;

    /** Whether the colour applies; a disabled field shows `disabledPlaceholder` instead of the text **/
    public var enabled(default, set):Bool = true;

    /** Whether the colour can't be changed right now; the text stays shown **/
    public var locked(default, set):Bool = false;

    public function new(label:String, initialText:String, onText:String->Void, disabledPlaceholder:String)
    {
        super();

        this.percentWidth = 100;
        this.verticalSpacing = 0; // FieldHeader's own margin-bottom is the only gap
        this.addClass("haxefolio-color-field");
        this.onTextChange = onText;
        this.disabledPlaceholder = disabledPlaceholder;

        header = new FieldHeader(label);
        header.height = AppearanceContext.current.geometry.messageLine;
        this.addComponent(header);

        box = new HBox();
        box.percentWidth = 100;
        box.addClass("haxefolio-color-field-box");
        this.addComponent(box);

        swatch = new Component();
        swatch.width = 22;
        swatch.height = 22;
        swatch.verticalAlign = "center";
        swatch.addClass("haxefolio-color-field-swatch");
        swatchInput = Browser.document.createInputElement();
        swatchInput.type = "color";
        swatchInput.setAttribute("aria-label", LocaleUtils.resolveText(label)); // fixed at build: a native attribute has no locale binding
        swatchInput.className = "haxefolio-color-field-native-swatch";
        swatchInput.addEventListener("input", onSwatchPicked);
        swatch.element.appendChild(swatchInput);
        box.addComponent(swatch);

        input = new AutofillNeutralTextField();
        input.percentWidth = 100;
        input.verticalAlign = "center";
        input.maxChars = 7;
        input.addClass("haxefolio-color-field-input");
        input.onChange = onInputChanged;
        box.addComponent(input);

        nativeInput().addEventListener("focusin", () -> box.addClass("haxefolio-color-field-box-focused"));
        nativeInput().addEventListener("focusout", () -> box.removeClass("haxefolio-color-field-box-focused"));

        heightBinding = ResponsivityController.bind(AppearanceContext.current.geometry.fieldHeight, height -> box.height = height);

        NativeSwatchStyle.inject();

        this.currentText = initialText;
    }

    /**
        Detaches the breakpoint subscription for the box's height - call once the field is removed
        for good.
    **/
    public function dispose():Void
    {
        heightBinding.detach();
    }

    private function onSwatchPicked():Void
    {
        if (!editable())
            return;

        currentText = swatchInput.value.toLowerCase();
        onTextChange(typedText);
    }

    private function onInputChanged(_:UIEvent):Void
    {
        var current:String = input.text ?? "";

        if (!editable() || current == renderedText)
            return;

        renderedText = current;
        typedText = current;
        syncSwatch();
        onTextChange(current);
    }

    private function syncSwatch():Void
    {
        if (HEX_PATTERN.match(typedText))
            swatchInput.value = typedText.toLowerCase();
    }

    private function editable():Bool
    {
        return enabled && !locked;
    }

    private function render():Void
    {
        renderedText = enabled ? typedText : "";
        input.text = renderedText;
        input.placeholder = enabled ? null : disabledPlaceholder;
        input.disabled = !editable();
        swatchInput.disabled = !editable();
        header.locked = locked;

        // on the input itself: the placeholder may want another face than the hex
        if (enabled)
            input.removeClass("haxefolio-color-field-input-unused");
        else
            input.addClass("haxefolio-color-field-input-unused");

        if (editable())
            box.removeClass("haxefolio-color-field-box-disabled");
        else
            box.addClass("haxefolio-color-field-box-disabled");

        syncSwatch();
    }

    private function nativeInput():Element
    {
        var root:Element = input.element;
        return root.tagName == "INPUT" ? root : root.querySelector("input");
    }

    private function get_currentText():String
    {
        return typedText;
    }

    private function set_currentText(value:String):String
    {
        typedText = value;
        render();
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
            box.addClass("haxefolio-color-field-box-invalid");
        else
            box.removeClass("haxefolio-color-field-box-invalid");

        return value;
    }

    private function set_enabled(value:Bool):Bool
    {
        enabled = value;
        render();
        return value;
    }

    private function set_locked(value:Bool):Bool
    {
        locked = value;
        render();
        return value;
    }
}

/*
    The native swatch's own chrome (its inner padding and border) can only be reached through
    vendor pseudo-elements, which HaxeUI's style engine doesn't know, so they go into a plain
    document stylesheet, once.
*/
private class NativeSwatchStyle
{
    private static var injected:Bool = false;

    public static function inject():Void
    {
        if (injected)
            return;

        injected = true;

        var style:Element = Browser.document.createElement("style");
        style.textContent = [
            ".haxefolio-color-field-native-swatch { display: block; box-sizing: border-box; width: 22px; height: 22px; margin: 0; padding: 0; border: 1px solid rgba(0, 0, 0, 0.2); border-radius: 4px; background: none; cursor: pointer; }",
            ".haxefolio-color-field-native-swatch:disabled { opacity: 0.4; cursor: not-allowed; }",
            ".haxefolio-color-field-native-swatch::-webkit-color-swatch-wrapper { padding: 0; }",
            ".haxefolio-color-field-native-swatch::-webkit-color-swatch { border: none; border-radius: 3px; }",
            ".haxefolio-color-field-native-swatch::-moz-color-swatch { border: none; border-radius: 3px; }"
        ].join("\n");
        Browser.document.head.appendChild(style);
    }
}
