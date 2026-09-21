package haxefolio.structure;

import haxe.ui.containers.HBox;
import haxefolio.appearance.AppearanceContext;

/**
    A row of `ActionButton`s: percentage widths, one of them typically primary (see
    `EmphasisStyle`), each centred vertically in the bar. It is what the `Actions` region of a
    `RegionStack` holds, but is independent of where it sits - a toolbar at the top is the same
    component.

    A button given a `widthPercent` keeps it; the rest split what remains evenly. The host keeps
    its own references to the buttons it needs to change later (e.g. to disable the primary one
    while a field is invalid).
**/
class ActionBar extends HBox
{
    public function new(buttons:Array<ActionButton>)
    {
        super();

        this.percentWidth = 100;
        this.percentHeight = 100;
        this.horizontalSpacing = AppearanceContext.current.geometry.rowGap;
        this.paddingLeft = AppearanceContext.current.geometry.padding;
        this.paddingRight = AppearanceContext.current.geometry.padding;
        this.addClass("haxefolio-action-bar");

        var claimed:Float = 0;
        var unclaimed:Int = 0;

        for (button in buttons)
        {
            if (button.percentWidth != null)
                claimed += button.percentWidth;
            else
                unclaimed++;
        }

        for (button in buttons)
        {
            if (button.percentWidth == null)
                button.percentWidth = Math.max(0, 100 - claimed) / unclaimed;

            button.verticalAlign = "center";
            this.addComponent(button);
        }
    }
}
