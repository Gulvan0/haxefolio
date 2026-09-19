package haxefolio.form;

import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.form.plumbing.FieldHeader;

/*
    An optional labelled header (see FieldHeader), the section's children, and the standard bottom
    margin (`.haxefolio-form-section` in main.css) that keeps inter-section rhythm out of every
    caller's hands.

    Locking (`locked`/`lockReason`) disables every child in place - never hides them - and states
    the reason via the header's own hint, per Lockable. Disabling is done on the content box
    rather than per child, so it also covers children that have no `locked` parameter of their own
    (HaxeUI cascades `disabled` down to descendants).
*/
class FormSection extends VBox
{
    private static inline final CHILD_SPACING:Int = 8;

    public function new(?label:String, ?headerHint:String, children:Array<Component>, locked:Bool = false, ?lockReason:String)
    {
        super();

        if (locked && label == null)
            throw "FormSection: locked without a label, so there is no header to state the lock reason in";

        this.percentWidth = 100;
        this.verticalSpacing = 0; // FieldHeader's own margin-bottom is this section's only header-to-content gap
        this.addClass("haxefolio-form-section");

        if (label != null)
            this.addComponent(new FieldHeader(label, locked ? lockReason : headerHint, Normal, locked));

        var content:VBox = new VBox();
        content.percentWidth = 100;
        content.verticalSpacing = CHILD_SPACING;
        content.disabled = locked;
        this.addComponent(content);

        for (child in children)
            content.addComponent(child);
    }
}
