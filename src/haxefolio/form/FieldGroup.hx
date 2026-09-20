package haxefolio.form;

import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.ByWidth;
import haxefolio.form.plumbing.FieldGroupDirection;
import morestd.Detachable;

/*
    A `surfaceSunken` inset box that groups fields belonging to one parameter - a row or a stack
    depending on `direction`, fixed-height whenever its contents can vary (`fixedHeight`).

    `direction` and `fixedHeight` are `ByWidth`s, so a group can lay its fields out side by side
    while expanded and stack them while collapsed (see `ResponsivityController.bind`). A field's
    own `percentWidth` is what it gets while the group is horizontal - it is remembered at
    construction and replaced by 100 while vertical, so the caller states the side-by-side split
    once and never branches on the breakpoint.

    The box itself is a plain VBox holding a single genuine HBox/VBox, replaced with the other kind
    (the fields moved across) whenever `direction` flips, rather than one Box with `layout` swapped
    in place: that approach measured the container's own `percentWidth` against its children's
    resolved size instead of the other way around (`percentWidth` children inflated the container
    far past its intended 100%). A genuine `HBox`/`VBox` does not have that problem.
*/
class FieldGroup extends VBox
{
    private final fields:Array<Component>;
    private final horizontalPercentWidths:Array<Null<Float>>;
    private final directionBinding:Detachable;
    private final heightBinding:Null<Detachable>;
    private var content:Null<Component>;

    public function new(fields:Array<Component>, ?direction:ByWidth<FieldGroupDirection>, ?fixedHeight:ByWidth<Int>)
    {
        super();

        this.percentWidth = 100;
        this.addClass("haxefolio-field-group");
        this.fields = fields;
        this.horizontalPercentWidths = [for (field in fields) field.percentWidth];

        var resolvedDirection:ByWidth<FieldGroupDirection> = FieldGroupDirection.Vertical;
        if (direction != null)
            resolvedDirection = direction;

        directionBinding = ResponsivityController.bind(resolvedDirection, applyDirection);
        heightBinding = fixedHeight != null ? ResponsivityController.bind(fixedHeight, applyHeight) : null;
    }

    /**
        Detaches this group's breakpoint subscriptions (see `ResponsivityController.bind`) - call
        once the group is removed for good (e.g. from a page's `onClose`). A no-op unless
        `direction`/`fixedHeight` differ between the two breakpoint states.
    **/
    public function dispose():Void
    {
        directionBinding.detach();

        if (heightBinding != null)
            heightBinding.detach();
    }

    private function applyDirection(direction:FieldGroupDirection):Void
    {
        for (field in fields)
        {
            if (field.parentComponent != null)
                field.parentComponent.removeComponent(field, false);
        }

        if (content != null)
            this.removeComponent(content);

        var horizontal:Bool = direction == Horizontal;

        content = horizontal ? new HBox() : new VBox();
        content.percentWidth = 100;
        this.addComponent(content);

        for (i in 0...fields.length)
        {
            fields[i].percentWidth = horizontal ? horizontalPercentWidths[i] : 100;
            content.addComponent(fields[i]);
        }
    }

    private function applyHeight(height:Int):Void
    {
        this.height = height;
    }
}
