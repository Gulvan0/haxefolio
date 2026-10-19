package haxefolio.structure;

import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;
import haxefolio.appearance.AppearanceContext;
import haxefolio.form.plumbing.AutofillNeutralTextField;
import haxefolio.form.plumbing.ClearButton;
import haxefolio.form.plumbing.HintLine;
import js.Browser;
import js.html.Element;
import morestd.Detachable;

/**
    A search input: a magnifier on the left, a clear control on the right while there is text, and
    optionally a message line under it (a result count, say). It is what the `Search` region of a
    `RegionStack` holds.

    The input is `fieldHeight` tall and the bar is padded by the `padding` token on both sides. Its
    top inset and the gap above the message line are the stylesheet's (`.haxefolio-search-bar`'s
    `padding-top` and `vertical-spacing`), as is the region's height (`searchBarHeight`) the host
    fits them into.

    Every user edit, a clear included, goes to `onQuery`; when to search is the host's call.
**/
class SearchBar extends VBox
{
    private static inline final MAGNIFIER_LANE_WIDTH:Int = 34;
    private static inline final MAGNIFIER_INSET:Int = 11;
    private static inline final GLYPH_SIZE:Int = 16;

    private final input:AutofillNeutralTextField;
    private final placeholderLabel:Label;
    private final clearButton:ClearButton;
    private final messageLine:Null<HintLine>;
    private final onQuery:String->Void;
    private final heightBinding:Detachable;
    private var renderedQuery:String = "";

    /**
        Reading returns what the input currently holds. Assigning renders the text without calling
        `onQuery` (the assigner already knows).
    **/
    public var query(get, set):String;

    /**
        The text of the message line; `null` or empty leaves it blank (it keeps its height). Only
        for a bar built with one.
    **/
    public var message(get, set):Null<String>;

    /**
        `placeholder` (interpreted like any HaxeUI `.text` property) shows while the input is empty.
        `maxChars` caps what can be typed (`null` for no cap).
    **/
    public function new(placeholder:String, onQuery:String->Void, withMessageLine:Bool = false, ?maxChars:Int)
    {
        super();

        this.onQuery = onQuery;
        this.percentWidth = 100;
        this.percentHeight = 100;
        this.paddingLeft = AppearanceContext.current.geometry.padding;
        this.paddingRight = AppearanceContext.current.geometry.padding;
        this.addClass("haxefolio-search-bar");

        // the lanes and the placeholder are drawn over the input's edges, inside its padding
        var inputBox:Box = new Box();
        inputBox.percentWidth = 100;
        this.addComponent(inputBox);

        input = new AutofillNeutralTextField();
        input.percentWidth = 100;
        input.paddingLeft = MAGNIFIER_LANE_WIDTH;
        input.addClass("haxefolio-text-input");
        input.addClass("haxefolio-search-input");
        if (maxChars != null)
            input.maxChars = maxChars;
        input.onChange = onInputChanged;
        inputBox.addComponent(input);

        var magnifier:Box = new Box();
        magnifier.width = MAGNIFIER_LANE_WIDTH;
        magnifier.percentHeight = 100;
        magnifier.addClass("haxefolio-search-magnifier");
        magnifier.element.style.pointerEvents = "none";
        magnifier.element.appendChild(magnifierGlyph());
        inputBox.addComponent(magnifier);

        placeholderLabel = new Label();
        placeholderLabel.text = placeholder;
        placeholderLabel.verticalAlign = "center";
        placeholderLabel.marginLeft = MAGNIFIER_LANE_WIDTH;
        placeholderLabel.addClass("haxefolio-search-placeholder");
        placeholderLabel.element.style.pointerEvents = "none"; // a click on it lands on the input
        inputBox.addComponent(placeholderLabel);

        clearButton = new ClearButton(clear);
        clearButton.horizontalAlign = "right";
        clearButton.verticalAlign = "center";
        clearButton.hidden = true;
        inputBox.addComponent(clearButton);

        if (withMessageLine)
        {
            messageLine = new HintLine();
            messageLine.addClass("haxefolio-search-message");
            this.addComponent(messageLine);
        }
        else
            messageLine = null;

        // HaxeUI's own :active (focused) state is driven by the FocusManager, which HaxeFolio disables
        input.element.addEventListener("focusin", () -> input.addClass("haxefolio-text-input-focused"));
        input.element.addEventListener("focusout", () -> input.removeClass("haxefolio-text-input-focused"));

        heightBinding = ResponsivityController.bind(AppearanceContext.current.geometry.fieldHeight, applyFieldHeight);
    }

    /**
        Detaches the breakpoint subscription for the input's height - call once the bar is removed
        for good. A no-op unless `fieldHeight` differs between the two breakpoint states.
    **/
    public function dispose():Void
    {
        heightBinding.detach();
    }

    /**
        Moves keyboard focus into the input. Goes to the native element directly, since HaxeFolio
        disables HaxeUI's FocusManager; the bar must already be on screen.
    **/
    public function focus():Void
    {
        var root:Element = input.element;
        var native:Null<Element> = root.tagName == "INPUT" ? root : root.querySelector("input");

        if (native != null)
            (cast native : Dynamic).focus({preventScroll: true});
    }

    private function clear():Void
    {
        if (query == "")
            return;

        query = "";
        onQuery("");
    }

    private function applyFieldHeight(height:Int):Void
    {
        input.height = height;
        input.paddingRight = height;
        clearButton.width = height;
        clearButton.height = height;
    }

    private function magnifierGlyph():Element
    {
        var glyph:Element = Browser.document.createSpanElement();
        glyph.style.cssText = 'position: absolute; left: ${MAGNIFIER_INSET}px; top: 50%; width: ${GLYPH_SIZE}px; height: ${GLYPH_SIZE}px; margin-top: -${GLYPH_SIZE >> 1}px;';
        glyph.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="$GLYPH_SIZE" height="$GLYPH_SIZE" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" style="display: block;"><circle cx="7" cy="7" r="4.5"/><path d="M10.5 10.5L14 14"/></svg>';
        return glyph;
    }

    private function renderEmptiness():Void
    {
        var empty:Bool = renderedQuery == "";
        placeholderLabel.hidden = !empty;
        clearButton.hidden = empty;
    }

    private function get_query():String
    {
        return input.text ?? "";
    }

    private function set_query(value:String):String
    {
        renderedQuery = value;
        input.text = value;
        renderEmptiness();
        return value;
    }

    private function get_message():Null<String>
    {
        return messageLine?.text;
    }

    private function set_message(value:Null<String>):Null<String>
    {
        if (messageLine != null)
            messageLine.text = value ?? "";
        return value;
    }

    /*
        As in TextInputField: a programmatic assignment makes HaxeUI dispatch CHANGE asynchronously,
        so only a genuine user edit makes the input's text differ from what was last rendered.
    */
    private function onInputChanged(_:UIEvent):Void
    {
        var current:String = query;

        if (current == renderedQuery)
            return;

        renderedQuery = current;
        renderEmptiness();
        onQuery(current);
    }
}
