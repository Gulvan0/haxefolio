package haxefolio.form;

import haxe.ui.Toolkit;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.layouts.HorizontalLayout;
import haxe.ui.layouts.VerticalLayout;
import haxefolio.ByMenuLayout;
import haxefolio.form.plumbing.ChoiceButton;
import haxefolio.form.plumbing.ChoiceOption;
import haxefolio.form.plumbing.FieldGroupDirection;
import haxefolio.form.plumbing.FieldHeader;
import haxefolio.form.plumbing.HintState;
import haxefolio.form.plumbing.IconAlign;
import morestd.Detachable;

/*
    An enumerable parameter as a row of equal-width ChoiceButtons under a header (see
    FieldHeader). Single-select: HaxeUI's own toggle-button `componentGroup` mechanism keeps
    exactly one button selected at a time, so this component does no selection bookkeeping of
    its own.

    Locking (`locked`/`lockReason`, or `setLocked` later) disables every button in place - never
    hides the row - and states the reason via the header's own hint, per Lockable. A single option
    may also be disabled on its own (`setOptionEnabled`), for a value the rest of the form rules out.
    `hint` is the header's hint while the row isn't locked (e.g. what the options mean).

    `joinButtons` turns a horizontal row into one segmented strip: no gaps, neighbours sharing a
    border, rounded only at the ends. Neighbours overlap by their border width, so the selected
    button (and the hovered one) is raised above the others to show its whole border.

    A `null` label leaves the header out, for a row labelled by its surroundings (e.g. a switch
    sitting in a section's heading); such a row has nowhere to state a lock reason.
*/
class ChoiceRow<T> extends VBox
{
    private static var nextGroupId:Int = 0;

    private final header:Null<FieldHeader>;
    private final buttonRow:HBox;
    private final buttons:Array<ChoiceButton> = [];
    private final optionValues:Array<T> = [];
    private final optionCount:Int;
    private final directionBinding:Detachable;
    private final disabledValues:Array<T> = [];
    private var locked:Bool;
    private var joined:Bool = false;
    private var lockReason:Null<String>;

    /** The header's hint while the row isn't locked **/
    public var hint(default, set):Null<String> = null;

    public function new(label:Null<String>, options:Array<ChoiceOption<T>>, selected:T, onSelect:T->Void, ?direction:ByMenuLayout<FieldGroupDirection>, locked:Bool = false, ?lockReason:String)
    {
        super();

        this.percentWidth = 100;
        this.verticalSpacing = 0; // FieldHeader's own margin-bottom is this row's only header-to-buttons gap
        this.addClass("haxefolio-choice-row");
        this.optionCount = options.length;
        this.locked = locked;
        this.lockReason = lockReason;

        if (label != null)
        {
            header = new FieldHeader(label, locked ? lockReason : null, Normal, locked);
            this.addComponent(header);
        }
        else
            header = null;

        buttonRow = new HBox();
        buttonRow.percentWidth = 100;
        buttonRow.addClass("haxefolio-choice-row-buttons");
        this.addComponent(buttonRow);

        var groupId:String = 'haxefolio-choice-row-group-${nextGroupId++}';

        for (option in options)
        {
            var button:ChoiceButton = new ChoiceButton(option.label, () -> {
                Toolkit.callLater(raiseSelected); // the group deselects the previous button after this
                onSelect(option.value);
            }, option.icon, Leading, option.value == selected, !locked);
            button.componentGroup = groupId;
            button.registerEvent(MouseEvent.MOUSE_OVER, _ -> raise(button, true));
            button.registerEvent(MouseEvent.MOUSE_OUT, _ -> raise(button, false));
            buttons.push(button);
            optionValues.push(option.value);
            buttonRow.addComponent(button);
        }

        var resolvedDirection:ByMenuLayout<FieldGroupDirection> = FieldGroupDirection.Horizontal;
        if (direction != null)
            resolvedDirection = direction;

        directionBinding = ResponsivityController.bind(resolvedDirection, applyDirection);
    }

    private function applyDirection(direction:FieldGroupDirection):Void
    {
        var stacked:Bool = direction == Vertical;

        buttonRow.layout = stacked ? new VerticalLayout() : new HorizontalLayout();

        for (button in buttons)
            button.percentWidth = stacked ? 100 : (100 / optionCount);
    }

    /**
        Selects the option holding `value` without calling `onSelect` - the hook for a value driven
        from elsewhere (e.g. a preference changed in another tab). Throws if no option holds `value`.
    **/
    public function select(value:T):Void
    {
        var index:Int = optionValues.indexOf(value);

        if (index == -1)
            throw 'ChoiceRow.select: no option holds value "$value"';

        buttons[index].selected = true;
        raiseSelected();
        Toolkit.callLater(raiseSelected); // the group deselects the previous button later still
    }

    /**
        Disables the option holding `value` alone, in place, or enables it back; a lock still
        disables every option, and lifting it keeps this one disabled. The selection is kept either
        way. Throws if no option holds `value`.
    **/
    public function setOptionEnabled(value:T, enabled:Bool):Void
    {
        var index:Int = optionValues.indexOf(value);

        if (index == -1)
            throw 'ChoiceRow.setOptionEnabled: no option holds value "$value"';

        disabledValues.remove(value);
        if (!enabled)
            disabledValues.push(value);

        buttons[index].disabled = locked || !enabled;
        raiseSelected();
    }

    /** Joins the buttons of a horizontal row into one segmented strip **/
    public function joinButtons():Void
    {
        joined = true;
        buttonRow.horizontalSpacing = -1; // neighbours share their 1px border
        buttonRow.element.style.setProperty("isolation", "isolate"); // the raised buttons stay below what covers the row
        buttonRow.addClass("haxefolio-choice-row-joined");

        for (i in 0...buttons.length)
        {
            buttons[i].addClass("haxefolio-choice-button-joined");
            if (i == 0)
                buttons[i].addClass("haxefolio-choice-button-joined-first");
            if (i == buttons.length - 1)
                buttons[i].addClass("haxefolio-choice-button-joined-last");
        }

        raiseSelected();
    }

    /**
        Locks the row (every button disabled in place, `lockReason` as the header's hint) or unlocks
        it. The selection is kept either way: `select` what a lock puts into effect, and back.
    **/
    public function setLocked(locked:Bool, ?lockReason:String):Void
    {
        this.locked = locked;
        this.lockReason = lockReason;
        renderHeader();

        for (i in 0...buttons.length)
            buttons[i].disabled = locked || disabledValues.contains(optionValues[i]);

        raiseSelected();
    }

    private function set_hint(value:Null<String>):Null<String>
    {
        hint = value;
        renderHeader();
        return value;
    }

    private function renderHeader():Void
    {
        if (header == null)
            return;

        header.locked = locked;
        header.hint = locked ? lockReason : hint;
    }

    private function raiseSelected():Void
    {
        for (button in buttons)
            raise(button, false);
    }

    // in a joined strip, the selected button above the hovered one above the enabled ones above the disabled ones
    private function raise(button:ChoiceButton, hovered:Bool):Void
    {
        if (!joined)
            return;

        var index:Int = buttons.indexOf(button);
        var disabled:Bool = locked || disabledValues.contains(optionValues[index]);
        button.element.style.zIndex = button.selected ? "3" : hovered ? "2" : disabled ? "" : "1";
    }

    /**
        Detaches this row's breakpoint subscription (see `ResponsivityController.bind`) - call once
        this row is removed for good (e.g. from a page's `onClose`). A no-op unless `direction`
        differs between the two breakpoint states.
    **/
    public function dispose():Void
    {
        directionBinding.detach();
    }
}
