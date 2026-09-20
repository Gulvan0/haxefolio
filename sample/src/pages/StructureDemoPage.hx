package pages;

import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.layouts.VerticalLayout;
import haxefolio.PageBase;
import haxefolio.structure.Region;
import haxefolio.structure.RegionStack;
import haxefolio.structure.SwapSlot;

enum DemoSlotVariant
{
    First;
    Second;
}

/*
    Demonstrates haxefolio.structure (RegionStack, ScrollArea, SwapSlot) as they're built.
    Grown incrementally alongside that work; not a permanent showcase of a finished API.
*/
class StructureDemoPage extends PageBase
{
    private var tallStack:RegionStack;
    private var slot:SwapSlot<DemoSlotVariant>;
    private var resizeLabel:Label;

    public function new()
    {
        super();
    }

    private override function init():Void
    {
        this.layout = new VerticalLayout();
        this.verticalSpacing = 6;

        setTitle("Structure Demo");

        resizeLabel = sectionLabel("onResize: (not called yet - resize the window)");
        addComponent(resizeLabel);

        addComponent(sectionLabel("RegionStack: header 60 / scroll / footer {expanded: 68, collapsed: 100}, frame 420"));

        tallStack = new RegionStack([
            Custom(60, filledBox("header (60)", "#e7e9ee")),
            Scroll(longContent()),
            Custom({expanded: 68, collapsed: 100}, filledBox("footer (68 expanded / 100 collapsed)", "#dcdfe5"))
        ], 420);
        tallStack.width = 480;
        tallStack.percentWidth = null;
        addComponent(tallStack);

        var resizeRow:HBox = new HBox();
        resizeRow.addComponent(button("Frame 420", () -> tallStack.frameHeight = 420));
        resizeRow.addComponent(button("Frame 260", () -> tallStack.frameHeight = 260));
        resizeRow.addComponent(button("Frame 100 (fixed exceed frame)", () -> tallStack.frameHeight = 100));
        addComponent(resizeRow);

        addComponent(sectionLabel("RegionStack with short content (gutter must stay reserved, no scrollbar thumb)"));

        var shortStack:RegionStack = new RegionStack([
            Custom(40, filledBox("header (40)", "#e7e9ee")),
            Scroll(shortContent()),
            Custom(40, filledBox("footer (40)", "#dcdfe5"))
        ], 220);
        shortStack.width = 480;
        shortStack.percentWidth = null;
        addComponent(shortStack);

        addComponent(sectionLabel("SwapSlot: height settable after construction"));

        var first:Label = new Label();
        first.text = "First variant";
        var second:Label = new Label();
        second.text = "Second variant";
        slot = new SwapSlot([First => first, Second => second], First, 40);
        slot.backgroundColor = 0xe7e9ee;
        addComponent(slot);

        var slotRow:HBox = new HBox();
        slotRow.addComponent(button("Slot height 40", () -> slot.height = 40));
        slotRow.addComponent(button("Slot height 90", () -> slot.height = 90));
        slotRow.addComponent(button("Swap", () -> slot.active = slot.active == First ? Second : First));
        addComponent(slotRow);
        addComponent(sectionLabel("(text below the slot: must move with the height)"));
    }

    private override function onResize(width:Float, height:Float):Void
    {
        resizeLabel.text = 'onResize: ${Math.round(width)} x ${Math.round(height)} (width excludes the 10px scrollbar lane)';
    }

    private override function onClose():Void
    {
        tallStack.dispose();
    }

    private function longContent():Component
    {
        var box:VBox = new VBox();
        box.percentWidth = 100;

        for (i in 1...41)
        {
            var line:Label = new Label();
            line.text = 'Scrolling line $i';
            box.addComponent(line);
        }

        return box;
    }

    private function shortContent():Component
    {
        var box:VBox = new VBox();
        box.percentWidth = 100;

        var line:Label = new Label();
        line.text = "Only line";
        box.addComponent(line);

        var bar:Box = new Box();
        bar.percentWidth = 100;
        bar.height = 20;
        bar.backgroundColor = 0xbfd8ff;
        box.addComponent(bar);

        return box;
    }

    private function filledBox(text:String, color:String):Component
    {
        var box:Box = new Box();
        box.percentWidth = 100;
        box.percentHeight = 100;
        box.styleString = 'background-color: $color;';

        var label:Label = new Label();
        label.text = text;
        box.addComponent(label);

        return box;
    }

    private function button(text:String, onClick:Void->Void):Button
    {
        var result:Button = new Button();
        result.text = text;
        result.onClick = _ -> onClick();
        return result;
    }

    private function sectionLabel(text:String):Label
    {
        var label:Label = new Label();
        label.text = text;
        label.addClass("sample-section-header");
        return label;
    }
}
