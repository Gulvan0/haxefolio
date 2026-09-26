package haxefolio.menu.builder.components;

import haxe.ui.components.Button;

/*
    One row of a side bar group: the item's icon, if it has one, and its label, as a full-width
    button - so the row as a whole is the touch target and shows the pressed state.
*/
class SidebarGroupItem extends Button
{
    public function new(groupSlug:String, itemSlug:String, text:String, onClick:Void->Void, ?icon:String, hiddenByDefault:Bool = false)
    {
        super();

        this.id = 'haxefolio-sidebar-group-item-$groupSlug-$itemSlug';
        this.text = text;
        this.addClass("haxefolio-sidebar-group-item");
        this.percentWidth = 100;
        this.hidden = hiddenByDefault;

        if (icon != null)
            this.icon = icon;

        this.onClick = _ -> onClick();
    }
}
