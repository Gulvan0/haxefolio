package pages;

import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.layouts.VerticalLayout;
import haxefolio.PageBase;
import haxefolio.form.ChoiceGrid;
import haxefolio.form.ChoiceRow;
import haxefolio.form.CommitTextField;
import haxefolio.form.DurationField;
import haxefolio.form.FieldGroup;
import haxefolio.form.FormSection;
import haxefolio.form.IntField;
import haxefolio.form.PreviewPane;
import haxefolio.form.SteppedValueField;
import haxefolio.form.SwapSlot;
import haxefolio.form.ToggleButton;
import haxefolio.form.plumbing.ChoiceButton;
import haxefolio.form.plumbing.ChoiceGridSelection;
import haxefolio.form.plumbing.ChoiceOption;
import haxefolio.form.plumbing.CommitResult;
import haxefolio.form.plumbing.CommitTrigger;
import haxefolio.form.plumbing.FieldGroupDirection;
import haxefolio.form.plumbing.FieldHeader;
import haxefolio.form.plumbing.HintLine;
import haxefolio.form.plumbing.IconAlign;
import haxefolio.form.plumbing.Stepper;

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

        addComponent(sectionLabel("Stepper (standalone, no value semantics)"));
        var standaloneText:Label = new Label();
        standaloneText.text = "Typed: (nothing yet)";
        var standaloneStepper:Stepper = new Stepper("5", text -> standaloneText.text = 'Typed: $text', direction -> standaloneText.text = 'Step: $direction');
        addComponent(standaloneStepper);
        addComponent(standaloneText);

        addComponent(sectionLabel("IntField 0..120 + DurationField 0:00..6:00:00 side by side (type past a bound / garbage to see errors)"));
        var lastValue:Label = new Label();
        lastValue.text = "onChange: (nothing yet)";
        var bonusGrid:Null<ChoiceGrid<Int>> = null;
        var bonusField:SteppedValueField<Int> = IntField.create("Bonus secs / turn", 5, value -> {
            lastValue.text = 'onChange: bonus = $value';
            bonusGrid.selectSingle(value);
        }, 0, 120, "max 120", "not a number", "out of range", true, valid -> trace('bonus valid: $valid'));
        bonusField.percentWidth = 50;
        var initialField:SteppedValueField<Int> = DurationField.create("Initial time", 300, value -> lastValue.text = 'onChange: initial = $value', 0, 21600, "max 6:00:00", "use m:ss", "out of range", true, valid -> trace('initial valid: $valid'));
        initialField.percentWidth = 50;
        addComponent(FieldGroup.create([initialField, bonusField], Horizontal, 90));
        addComponent(lastValue);

        var presetToOneHour:Button = new Button();
        presetToOneHour.text = "Set initial time to 1:00:00 externally";
        presetToOneHour.onClick = _ -> initialField.currentValue = 3600;
        addComponent(presetToOneHour);
        var disableToggle:Button = new Button();
        disableToggle.text = "Toggle enabled on both fields";
        disableToggle.onClick = _ -> {
            initialField.enabled = !initialField.enabled;
            bonusField.enabled = !bonusField.enabled;
        };
        addComponent(disableToggle);

        addComponent(sectionLabel("ChoiceGrid<Int> Single - presets bound to the bonus field above (type a non-preset value: highlight clears)"));
        var presetBonuses:Array<Int> = [0, 1, 2, 3, 5, 10, 15, 30, 60, 120];
        var presetOptions:Array<ChoiceOption<Int>> = [for (bonus in presetBonuses) {value: bonus, label: '+$bonus'}];
        bonusGrid = new ChoiceGrid("Bonus preset", presetOptions, Single(bonusField.currentValue, value -> bonusField.currentValue = value), {expanded: 5, collapsed: 3});
        addComponent(bonusGrid);

        addComponent(sectionLabel("ChoiceGrid<String> Multi (perRow 4 / 2, 7 options: short last row) + locked variant"));
        var multiLabel:Label = new Label();
        multiLabel.text = "Toggled: (nothing yet)";
        var multiOptions:Array<ChoiceOption<String>> = [for (name in ["Bullet", "Blitz", "Rapid", "Classical", "Daily", "Custom", "Other"]) {value: name, label: name}];
        addComponent(new ChoiceGrid("Time controls", multiOptions, Multi(["Blitz"], (value, nowSelected) -> multiLabel.text = 'Toggled: $value -> $nowSelected'), {expanded: 4, collapsed: 2}));
        addComponent(multiLabel);
        addComponent(new ChoiceGrid("Locked grid", multiOptions, Single("Rapid", value -> trace('locked grid changed: $value')), {expanded: 4, collapsed: 2}, 6, true, "Rated games fix this"));

        addComponent(sectionLabel("ToggleButton (off / on / disabled / driven externally)"));
        var toggleLabel:Label = new Label();
        toggleLabel.text = "Toggle: (nothing yet)";
        var driven:ToggleButton = new ToggleButton("No time control", on -> toggleLabel.text = 'Toggle: $on');
        addComponent(driven);
        addComponent(new ToggleButton("Already on", on -> trace('on: $on'), null, true));
        addComponent(new ToggleButton("Disabled", on -> trace('disabled toggled: $on'), null, false, false));
        addComponent(new ToggleButton("Disabled while on", on -> trace('disabled toggled: $on'), null, true, false));
        addComponent(toggleLabel);
        var flipDriven:Button = new Button();
        flipDriven.text = "Flip the first toggle externally";
        flipDriven.onClick = _ -> driven.on = !driven.on;
        addComponent(flipDriven);

        addComponent(sectionLabel("CommitTextField (apply 'ok' to succeed, anything else is rejected; editing returns to the idle hint)"));
        var typedLabel:Label = new Label();
        typedLabel.text = "Typed: (nothing yet)";
        addComponent(new CommitTextField(
            "Starting position",
            "ok",
            text -> typedLabel.text = 'Typed: $text',
            text -> text == "ok" ? Applied : Rejected('"$text" is not valid'),
            "Apply",
            "Edit the value, then press Apply",
            "Position applied"
        ));
        addComponent(typedLabel);
        addComponent(new CommitTextField("Enter only", "", text -> {}, text -> Applied, "Apply", "Type, then press Enter", "Applied", Enter));
        addComponent(new CommitTextField("Button only, disabled", "locked", text -> {}, text -> Applied, "Apply", "Locked", "Applied", CommitTrigger.Button, false));

        addComponent(sectionLabel("PreviewPane (fixed 200x80 area, caption row reserved; content and caption swapped by the button)"));
        var contentA:Label = new Label();
        contentA.text = "Content A";
        var contentB:Label = new Label();
        contentB.text = "Content B is far wider than the area and gets clipped cleanly at its edge";
        var pane:PreviewPane = new PreviewPane(200, 80, contentA, "White to move");
        addComponent(pane);
        var swapContent:Button = new Button();
        swapContent.text = "Swap content and caption";
        swapContent.onClick = _ -> {
            var showingA:Bool = pane.content == contentA;
            pane.content = showingA ? contentB : contentA;
            pane.caption = showingA ? "Black to move" : "White to move";
        };
        addComponent(swapContent);
        var captionless:Label = new Label();
        captionless.text = "No caption row at all";
        addComponent(new PreviewPane(200, 40, captionless));

        addComponent(sectionLabel("FormSection (plain / locked - the raw Button and Label inside are disabled by the section, not by their own parameter)"));
        addComponent(new FormSection("Plain section", "a hint", [
            new ChoiceRow("Rated", [
                { value: "rated", label: "Rated" },
                { value: "unrated", label: "Unrated" }
            ], "rated", value -> trace('selected: $value'))
        ]));
        var lockedButton:Button = new Button();
        lockedButton.text = "Disabled by the section";
        var lockedLabel:Label = new Label();
        lockedLabel.text = "Section bottom margin follows.";
        addComponent(new FormSection("Locked section", "not shown while locked", [lockedButton, lockedLabel], true, "Rated games fix this"));
        var unlabelled:Label = new Label();
        unlabelled.text = "Unlabelled section: no header row at all.";
        addComponent(new FormSection(null, null, [unlabelled]));
    }

    private function sectionLabel(text:String):Label
    {
        var label:Label = new Label();
        label.text = text;
        return label;
    }
}
