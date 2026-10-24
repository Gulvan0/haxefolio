package haxefolio.form;

import haxe.ui.components.Label;
import haxe.ui.components.TextArea;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;
import haxefolio.appearance.AppearanceContext;
import haxefolio.form.plumbing.FieldHeader;
import haxefolio.form.plumbing.HintState;
import js.html.Element;
import js.html.TextAreaElement;

/*
    The multi-line sibling of TextInputField: a FieldHeader whose right-hand hint is the field's
    single message slot, over a full-width text area of a fixed height that scrolls its own text.
    The host validates each edit through `onText` and writes back `hint`, `hintState` and `invalid`.
    Enter inserts a line break; there is no submit hook.
*/
class TextAreaField extends VBox
{
    private final header:FieldHeader;
    private final area:TextArea;
    private final placeholderLabel:Null<Label>;
    private final onTextChange:String->Void;
    private var renderedText:String = "";

    /**
        Reading returns what the area currently holds. Assigning renders the text without calling
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
        Whether the area shows the invalid border. It wins over the focus border.
    **/
    public var invalid(default, set):Bool = false;

    /**
        A disabled field greys out in place (area and label) and cannot be typed into.
    **/
    public var enabled(default, set):Bool;

    /**
        `areaHeight`: the text area's own height, the header excluded. `maxChars` caps what can be
        typed (`null` for no cap). `placeholder` is shown while the area is empty, drawn as a label over
        it since HaxeUI's own placeholder is written into the value.
    **/
    public function new(label:String, onText:String->Void, areaHeight:Int, ?maxChars:Int, ?placeholder:String, enabled:Bool = true)
    {
        super();

        this.percentWidth = 100;
        this.verticalSpacing = 0; // FieldHeader's own margin-bottom is the only gap
        this.addClass("haxefolio-text-area-field");
        this.onTextChange = onText;

        header = new FieldHeader(label);
        header.height = AppearanceContext.current.geometry.messageLine;
        this.addComponent(header);

        var areaBox:Box = new Box();
        areaBox.percentWidth = 100;
        this.addComponent(areaBox);

        area = new TextArea();
        area.percentWidth = 100;
        area.height = areaHeight;
        area.addClass("haxefolio-text-input");
        area.addClass("haxefolio-text-area");
        area.onChange = onAreaChanged;
        areaBox.addComponent(area);

        if (placeholder != null)
        {
            placeholderLabel = new Label();
            placeholderLabel.text = placeholder;
            placeholderLabel.percentWidth = 100;
            placeholderLabel.addClass("haxefolio-text-input-placeholder");
            placeholderLabel.addClass("haxefolio-text-area-placeholder");
            placeholderLabel.element.style.pointerEvents = "none"; // a click on it lands on the area
            areaBox.addComponent(placeholderLabel);
        }
        else
            placeholderLabel = null;

        var native:Null<Element> = nativeArea();
        if (native != null)
        {
            if (maxChars != null)
                native.setAttribute("maxlength", Std.string(maxChars));
            // HaxeUI's own :active (focused) state is driven by the FocusManager, which HaxeFolio disables
            native.addEventListener("focusin", () -> area.addClass("haxefolio-text-input-focused"));
            native.addEventListener("focusout", () -> area.removeClass("haxefolio-text-input-focused"));
        }

        this.enabled = enabled;
    }

    /**
        Moves keyboard focus into the area, caret at the end. The field must already be on screen.
    **/
    public function focus():Void
    {
        var native:Null<Element> = nativeArea();

        if (native != null)
            (cast native : Dynamic).focus({preventScroll: true});
    }

    private function refreshPlaceholder():Void
    {
        if (placeholderLabel != null)
            placeholderLabel.hidden = currentText.length > 0;
    }

    private function nativeArea():Null<Element>
    {
        var root:Element = area.element;
        return root.tagName == "TEXTAREA" ? root : root.querySelector("textarea");
    }

    private function get_currentText():String
    {
        var native:Null<Element> = nativeArea();
        return native != null ? (cast native : TextAreaElement).value : (area.text ?? "");
    }

    private function set_currentText(value:String):String
    {
        renderedText = value;
        area.text = value;
        var native:Null<Element> = nativeArea();
        if (native != null)
            (cast native : TextAreaElement).value = value; // HaxeUI writes it only on its next validation, which typing can overtake
        refreshPlaceholder();
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
            area.addClass("haxefolio-text-input-invalid");
        else
            area.removeClass("haxefolio-text-input-invalid");

        return value;
    }

    private function set_enabled(value:Bool):Bool
    {
        enabled = value;
        area.disabled = !value;
        header.locked = !value;
        return value;
    }

    // a programmatic assignment makes HaxeUI dispatch CHANGE asynchronously, so only a genuine user edit differs from what was last rendered
    private function onAreaChanged(_:UIEvent):Void
    {
        var current:String = currentText;

        if (current == renderedText)
            return;

        renderedText = current;
        refreshPlaceholder();
        onTextChange(current);
    }
}
