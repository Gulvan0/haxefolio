package pages;

import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.layouts.VerticalLayout;
import haxefolio.PageBase;
import haxefolio.form.ChoiceRow;
import haxefolio.form.FieldGroup;
import haxefolio.form.SwapSlot;
import haxefolio.form.plumbing.ChoiceButton;
import haxefolio.form.plumbing.FieldGroupDirection;
import haxefolio.form.plumbing.FieldHeader;
import haxefolio.form.plumbing.HintLine;
import haxefolio.form.plumbing.IconAlign;

enum DemoSwapVariant
{
    Direct;
    Open;
}

/*
    Demonstrates haxefolio.form components as they're built. Grown incrementally alongside
    that work; not a permanent showcase of a finished API.
*/
class FormDemoPage extends PageBase
{
    public function new()
    {
        super();
    }

    private override function init():Void
    {
        this.layout = new VerticalLayout();
        this.verticalSpacing = 6;

        setTitle("Form Demo");

        addComponent(sectionLabel("FieldHeader"));
        addComponent(new FieldHeader("Initial time", "max 6:00:00"));
        addComponent(new FieldHeader("Bonus secs / turn", "max 120", Error));
        addComponent(new FieldHeader("Colour", "Rated games use random colour", Normal, true));

        addComponent(sectionLabel("HintLine"));
        addComponent(new HintLine("This is a normal hint line."));
        addComponent(new HintLine("This is an error hint line.", Error));
        addComponent(new HintLine());

        addComponent(sectionLabel("ChoiceButton (standalone, not grouped)"));
        addComponent(new ChoiceButton("Unselected", () -> {}));
        addComponent(new ChoiceButton("Selected", () -> {}, null, Leading, true));
        addComponent(new ChoiceButton("Disabled", () -> {}, null, Leading, false, false));

        addComponent(sectionLabel("ChoiceRow<String>"));
        addComponent(new ChoiceRow("Rated", [
            { value: "rated", label: "Rated" },
            { value: "unrated", label: "Unrated" }
        ], "rated", value -> trace('selected: $value')));
        addComponent(new ChoiceRow("Colour (locked)", [
            { value: "white", label: "White" },
            { value: "random", label: "Random" },
            { value: "black", label: "Black" }
        ], "random", value -> trace('selected: $value'), false, true, "Rated games use random colour"));

        addComponent(sectionLabel("SwapSlot<DemoSwapVariant> (height stays 60px even though Open's content would naturally wrap to ~4 lines / 80px+)"));
        var directLabel:Label = new Label();
        directLabel.text = "Direct variant - short content.";
        var openLabel:Label = new Label();
        openLabel.wordWrap = true;
        openLabel.width = 260;
        openLabel.text = "Open variant has enough wrapped text across several lines that its natural height clearly exceeds the slot's fixed 60px, to actually test the clamp rather than just a width change.";
        var swapSlot:SwapSlot<DemoSwapVariant> = new SwapSlot([Direct => directLabel, Open => openLabel], Direct, 60);
        var toDirect:Button = new Button();
        toDirect.text = "Show Direct";
        toDirect.onClick = _ -> swapSlot.active = Direct;
        var toOpen:Button = new Button();
        toOpen.text = "Show Open";
        toOpen.onClick = _ -> swapSlot.active = Open;
        addComponent(toDirect);
        addComponent(toOpen);
        addComponent(swapSlot);

        addComponent(sectionLabel("FieldGroup (horizontal, fixed height)"));
        var left:Label = new Label();
        left.text = "Left child";
        left.percentWidth = 50;
        var right:Label = new Label();
        right.text = "Right child";
        right.percentWidth = 50;
        right.textAlign = "right";
        addComponent(FieldGroup.create([left, right], Horizontal, 44)); // 12px padding + 20px single-line label + 12px padding
    }

    private function sectionLabel(text:String):Label
    {
        var label:Label = new Label();
        label.text = text;
        return label;
    }
}
