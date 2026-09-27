package haxefolio.form;

import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import haxefolio.appearance.AppearanceContext;
import js.html.KeyboardEvent;
import morestd.Detachable;

/*
    A boolean attribute as a checkbox: a 16px box and a caption on one row, the whole row being the
    hit target and `fieldHeight` tall (so it reaches the touch height wherever the token does). The
    checked state is drawn per the app's `selectionEmphasis`, like a selected ChoiceButton: `Filled`
    fills the box with `accent`, `Outlined` tints it and outlines it in `accentMuted`.

    Built from plain boxes rather than on HaxeUI's CheckBox, whose mark is an image the stylesheet
    cannot recolour per emphasis. It is keyboard-reachable on its own (tabindex, Space/Enter toggle),
    since HaxeFolio disables HaxeUI's FocusManager.

    Use a ToggleButton instead when the boolean is a mode rather than an attribute.
*/
class CheckBoxRow extends HBox
{
    private static inline final MARK:String = "✓";

    private final box:Box;
    private final mark:Label;
    private final onToggle:Bool->Void;
    private final heightBinding:Detachable;

    /**
        Whether the box is checked. Assigning renders it without calling `onToggle` (the assigner
        already knows).
    **/
    public var checked(default, set):Bool;

    /**
        A disabled row greys out in place and ignores clicks and keys.
    **/
    public var enabled(default, set):Bool;

    public function new(caption:String, onToggle:Bool->Void, initiallyChecked:Bool = false, initiallyEnabled:Bool = true)
    {
        super();

        this.onToggle = onToggle;
        this.horizontalSpacing = 8;
        this.addClass("haxefolio-check-box-row");

        if (AppearanceContext.current.selectionEmphasis == Outlined)
            this.addClass("haxefolio-check-box-row-outlined");

        box = new Box();
        box.width = 16;
        box.height = 16;
        box.verticalAlign = "center";
        box.addClass("haxefolio-check-box");
        this.addComponent(box);

        mark = new Label();
        mark.text = MARK;
        mark.horizontalAlign = "center";
        mark.verticalAlign = "center";
        mark.addClass("haxefolio-check-box-mark");
        box.addComponent(mark);

        var label:Label = new Label();
        label.text = caption;
        label.verticalAlign = "center";
        label.addClass("haxefolio-check-box-label");
        this.addComponent(label);

        heightBinding = ResponsivityController.bind(AppearanceContext.current.geometry.fieldHeight, height -> this.height = height);

        this.registerEvent(MouseEvent.CLICK, _ -> toggle());

        this.element.tabIndex = 0;
        this.element.addEventListener("keydown", onKeyDown);

        this.checked = initiallyChecked;
        this.enabled = initiallyEnabled;
    }

    /**
        Detaches the breakpoint subscription for the row's height - call once the row is removed for
        good. A no-op unless `fieldHeight` differs between the two breakpoint states.
    **/
    public function dispose():Void
    {
        heightBinding.detach();
    }

    private function toggle():Void
    {
        if (!enabled)
            return;

        checked = !checked;
        onToggle(checked);
    }

    private function onKeyDown(event:KeyboardEvent):Void
    {
        if (event.key != " " && event.key != "Enter")
            return;

        event.preventDefault();
        toggle();
    }

    private function set_checked(value:Bool):Bool
    {
        checked = value;
        mark.hidden = !value;

        if (value)
            this.addClass("haxefolio-check-box-row-checked");
        else
            this.removeClass("haxefolio-check-box-row-checked");

        return value;
    }

    private function set_enabled(value:Bool):Bool
    {
        enabled = value;
        this.disabled = !value;
        this.element.tabIndex = value ? 0 : -1;
        return value;
    }
}
