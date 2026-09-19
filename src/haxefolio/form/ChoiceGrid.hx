package haxefolio.form;

import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.form.plumbing.ChoiceButton;
import haxefolio.form.plumbing.ChoiceGridSelection;
import haxefolio.form.plumbing.ChoiceOption;
import haxefolio.form.plumbing.ChoicesPerRow;
import haxefolio.form.plumbing.FieldHeader;
import morestd.Detachable;

/*
    The same selection semantics as ChoiceRow, but wrapping, for 6-20 curated options - under a
    FieldHeader, in rows of `perRow.expanded`/`perRow.collapsed` cells (keyed off
    `ResponsivityController.isCollapsed`, the framework's one app-wide breakpoint).

    Cell width is a percentage of the row, never pixels, so a host's scrollbar gutter or a padding
    change cannot push the last cell onto another row; a final short row is padded with empty
    placeholders so its cells stay exactly as wide as the full rows' ones. Wrapping is done with
    explicit rows rebuilt on each breakpoint flip rather than a wrapping container, so the
    placement never depends on the layout engine's wrap heuristics.

    `Single` mode's `selected` is nullable, and that is the design: a grid of presets is a
    shortcut *into* a value, not the value itself. The grid highlights what `selectSingle` last
    told it - not which cell was clicked - so a host that also lets the user type a custom value
    computes the highlight from the value (or `null` when no preset matches) and calls
    `selectSingle` on every change, with no synchronisation state of its own. A click still
    highlights its cell immediately, so the grid also works unbound.

    Selection is tracked by the grid itself rather than via HaxeUI's toggle-button
    `componentGroup`, which cannot express "none selected". In `Multi` mode `selected` is exactly
    the set of checked options.

    Locking (`locked`/`lockReason`) disables every button in place, and states the reason via the
    header's hint, per Lockable.
*/
class ChoiceGrid<T> extends VBox
{
    private final options:Array<ChoiceOption<T>>;
    private final selection:ChoiceGridSelection<T>;
    private final perRow:ChoicesPerRow;
    private final gap:Int;
    private final rowContainer:VBox;
    private final buttons:Array<ChoiceButton> = [];
    private final collapseListener:Detachable;
    private var selectedSingle:Null<T>;
    private var selectedMulti:Array<T>;

    public function new(label:String, options:Array<ChoiceOption<T>>, selection:ChoiceGridSelection<T>, perRow:ChoicesPerRow, gap:Int = 6, locked:Bool = false, ?lockReason:String)
    {
        super();

        this.percentWidth = 100;
        this.verticalSpacing = 0; // FieldHeader's own margin-bottom is this grid's only header-to-cells gap
        this.addClass("haxefolio-choice-grid");
        this.options = options;
        this.selection = selection;
        this.perRow = perRow;
        this.gap = gap;

        switch selection
        {
            case Single(selected, _):
                selectedSingle = selected;
                selectedMulti = [];
            case Multi(selected, _):
                selectedSingle = null;
                selectedMulti = selected.copy();
        }

        this.addComponent(new FieldHeader(label, locked ? lockReason : null, Normal, locked));

        rowContainer = new VBox();
        rowContainer.percentWidth = 100;
        rowContainer.verticalSpacing = gap;
        this.addComponent(rowContainer);

        for (option in options)
        {
            var button:ChoiceButton = new ChoiceButton(option.label, () -> onCellClicked(option.value), option.icon, Leading, false, !locked);
            buttons.push(button);
        }

        renderSelection();

        collapseListener = ResponsivityController.onCollapseChange(rebuildRows);
    }

    /**
        `Single` mode only: highlights the cell holding `value` (or none, for `null`) without
        calling `onSelect`. Throws in `Multi` mode.
    **/
    public function selectSingle(value:Null<T>):Void
    {
        switch selection
        {
            case Single(_, _):
                selectedSingle = value;
                renderSelection();
            case Multi(_, _):
                throw "ChoiceGrid.selectSingle called on a Multi grid";
        }
    }

    /**
        `Multi` mode only: replaces the checked set without calling `onToggle`. Throws in `Single` mode.
    **/
    public function selectMulti(values:Array<T>):Void
    {
        switch selection
        {
            case Multi(_, _):
                selectedMulti = values.copy();
                renderSelection();
            case Single(_, _):
                throw "ChoiceGrid.selectMulti called on a Single grid";
        }
    }

    /**
        Detaches this grid's `ResponsivityController.onCollapseChange` listener - call once the
        grid is removed for good (e.g. from a page's `onClose`).
    **/
    public function dispose():Void
    {
        collapseListener.detach();
    }

    private function onCellClicked(value:T):Void
    {
        switch selection
        {
            case Single(_, onSelect):
                selectedSingle = value;
                renderSelection();
                onSelect(value);
            case Multi(_, onToggle):
                var nowSelected:Bool = !selectedMulti.contains(value);

                if (nowSelected)
                    selectedMulti.push(value);
                else
                    selectedMulti.remove(value);

                renderSelection();
                onToggle(value, nowSelected);
        }
    }

    private function renderSelection():Void
    {
        for (i in 0...options.length)
        {
            buttons[i].selected = switch selection {
                case Single(_, _): selectedSingle != null && options[i].value == selectedSingle;
                case Multi(_, _): selectedMulti.contains(options[i].value);
            }
        }
    }

    private function rebuildRows(collapsed:Bool):Void
    {
        var cellsPerRow:Int = collapsed ? perRow.collapsed : perRow.expanded;

        for (button in buttons)
        {
            if (button.parentComponent != null)
                button.parentComponent.removeComponent(button, false);
        }
        rowContainer.removeAllComponents();

        var index:Int = 0;
        while (index < buttons.length)
        {
            var row:HBox = new HBox();
            row.percentWidth = 100;
            row.horizontalSpacing = gap;
            rowContainer.addComponent(row);

            for (_ in 0...cellsPerRow)
            {
                var cell:Component = index < buttons.length ? buttons[index] : new Component();
                cell.percentWidth = 100 / cellsPerRow;
                row.addComponent(cell);
                index++;
            }
        }
    }
}
