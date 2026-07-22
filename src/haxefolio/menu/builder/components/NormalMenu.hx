package haxefolio.menu.builder.components;

import haxe.ui.containers.menus.Menu;

class NormalMenu extends Menu
{
    public function new(slug:String, items:Array<MenuItemDefinition>)
    {
        super();

        this.id = 'haxefolio-normal-menu-$slug';
        this.text = Utils.localeBinding('haxefolio.menubar.menu.$slug');
        this.addClass('haxefolio-normal-menu');
        this.verticalAlign = "center";

        for (item in items)
            this.addComponent(new NormalMenuItem(slug, item));
    }
}
