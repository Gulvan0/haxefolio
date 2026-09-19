package haxefolio.form.plumbing;

import haxe.ui.components.Button;

/*
    One selectable button - the atom of both ChoiceRow and ChoiceGrid. Built on HaxeUI's own
    `Button` toggle mode (`toggle = true`) rather than from scratch: `selected` is the toggled
    state, and `componentGroup` (set by a caller composing several of these, e.g. ChoiceRow) is
    what HaxeUI uses natively to keep only one button in a group selected at a time.

    Selected styling hooks off `:down` - the pseudo-class HaxeUI's toggle Button already applies
    for as long as `selected == true` (not just while the mouse is actually held) - rather than a
    class this component would otherwise have to toggle itself on every selection change. Which
    treatment (`Filled`/`Outlined`) `:down` resolves to is not a property here at all - see
    `EmphasisStyle`.

    Disabled and selected at once (`:down:disabled`) gets its own muted look, so a locked row
    still shows the value actually in effect. That chained selector needs a haxeui-core that keeps
    every pseudo-class of a selector part (haxeui-core PR #713); stock versions read it as `:down`.
*/
class ChoiceButton extends Button
{
    public function new(label:String, onClick:Void->Void, ?icon:String, iconAlign:IconAlign = Leading, selected:Bool = false, enabled:Bool = true)
    {
        super();

        this.addClass("haxefolio-choice-button");
        this.toggle = true;
        this.text = label;
        this.selected = selected;
        this.disabled = !enabled;
        this.iconPosition = iconAlign == Leading ? "left" : "right";

        if (icon != null)
            this.icon = icon;

        this.onClick = _ -> onClick();
    }
}
