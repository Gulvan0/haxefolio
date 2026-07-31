package haxefolio.menu.builder.components;

import haxe.ui.components.Label;

class SidebarGroupItem extends Label
{
    public function new(groupSlug:String, itemSlug:String, text:String, onClick:Void->Void, hiddenByDefault:Bool = false)
    {
        super();

        this.id = 'haxefolio-sidebar-group-item-$groupSlug-$itemSlug';
        this.text = text;
        this.addClass("haxefolio-sidebar-group-item");
        this.hidden = hiddenByDefault;
        this.onClick = _ -> onClick();
    }
}
