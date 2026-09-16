package haxefolio.form;

import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.layouts.HorizontalLayout;
import haxe.ui.layouts.VerticalLayout;
import haxefolio.form.plumbing.ChoiceButton;
import haxefolio.form.plumbing.ChoiceOption;
import haxefolio.form.plumbing.FieldHeader;
import haxefolio.form.plumbing.HintState;
import haxefolio.form.plumbing.IconAlign;
import morestd.Detachable;

/*
    An enumerable parameter as a row of equal-width ChoiceButtons under a header (see
    FieldHeader). Single-select: HaxeUI's own toggle-button `componentGroup` mechanism keeps
    exactly one button selected at a time, so this component does no selection bookkeeping of
    its own.

    Locking (`locked`/`lockReason`) disables every button in place - never hides the row - and
    states the reason via the header's own hint, per Lockable.
*/
class ChoiceRow<T> extends VBox
{
    private static var nextGroupId:Int = 0;

    private final buttonRow:HBox;
    private final buttons:Array<ChoiceButton> = [];
    private final optionCount:Int;
    private final collapseListener:Null<Detachable>;

    public function new(label:String, options:Array<ChoiceOption<T>>, selected:T, onSelect:T->Void, stackOnCollapse:Bool = false, locked:Bool = false, ?lockReason:String)
    {
        super();

        this.percentWidth = 100;
        this.verticalSpacing = 0; // FieldHeader's own margin-bottom is this row's only header-to-buttons gap
        this.addClass("haxefolio-choice-row");
        this.optionCount = options.length;

        this.addComponent(new FieldHeader(label, locked ? lockReason : null, Normal, locked));

        buttonRow = new HBox();
        buttonRow.percentWidth = 100;
        buttonRow.addClass("haxefolio-choice-row-buttons");
        this.addComponent(buttonRow);

        var groupId:String = 'haxefolio-choice-row-group-${nextGroupId++}';

        for (option in options)
        {
            var button:ChoiceButton = new ChoiceButton(option.label, () -> onSelect(option.value), option.icon, Leading, option.value == selected, !locked);
            button.componentGroup = groupId;
            buttons.push(button);
            buttonRow.addComponent(button);
        }

        collapseListener = stackOnCollapse ? ResponsivityController.onCollapseChange(applyStacking) : null;
        if (!stackOnCollapse)
            applyStacking(false);
    }

    private function applyStacking(collapsed:Bool):Void
    {
        buttonRow.layout = collapsed ? new VerticalLayout() : new HorizontalLayout();

        for (button in buttons)
            button.percentWidth = collapsed ? 100 : (100 / optionCount);
    }

    /**
        Detaches this row's `ResponsivityController.onCollapseChange` listener, if `stackOnCollapse`
        was `true` - call once this row is removed for good (e.g. from a page's `onClose`).
    **/
    public function dispose():Void
    {
        if (collapseListener != null)
            collapseListener.detach();
    }
}
