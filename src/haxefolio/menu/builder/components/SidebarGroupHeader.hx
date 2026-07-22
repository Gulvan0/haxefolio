package haxefolio.menu.builder.components;

import haxe.ui.components.Label;

class SidebarGroupHeader extends Label
{
    public function new(slug:String, text:String)
    {
        super();

        this.id = 'haxefolio-sidebar-group-header-$slug';
        this.text = text;
        this.addClass("haxefolio-sidebar-group-header");
    }
}
