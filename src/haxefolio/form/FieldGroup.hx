package haxefolio.form;

import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.form.plumbing.FieldGroupDirection;

/*
    A `surfaceSunken` inset box that groups fields belonging to one parameter - a row or a stack
    depending on `direction`, fixed-height whenever its contents can vary (`fixedHeight`).

    `direction` is set once by the caller, not derived from a breakpoint - a layout choice, not a
    responsive behaviour (see ChoiceRow's `stackOnCollapse` for the latter kind).

    A static factory rather than a class extending a base `Box` with `layout` swapped after
    construction to pick horizontal/vertical: that approach measured the container's own
    `percentWidth` against its children's resolved size instead of the other way around
    (`percentWidth` children inflated the container far past its intended 100%). A genuine
    `HBox`/`VBox` does not have that problem, and Haxe has no way to extend either
    conditionally - hence returning one directly instead of wrapping it in a `FieldGroup`
    instance.
*/
class FieldGroup
{
    public static function create(children:Array<Component>, direction:FieldGroupDirection = Vertical, ?fixedHeight:Int):Component
    {
        var container:Component = direction == Horizontal ? new HBox() : new VBox();
        container.percentWidth = 100;
        container.addClass("haxefolio-field-group");

        if (fixedHeight != null)
            container.height = fixedHeight;

        for (child in children)
            container.addComponent(child);

        return container;
    }
}
