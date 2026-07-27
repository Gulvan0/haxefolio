package haxefolio.menu.builder.components;

import haxe.ui.containers.menus.Menu;
import haxefolio.menu.builder.MenuBuilderHelpers;

class NormalMenu extends Menu
{
    public function new(slug:String, items:Array<MenuItemDefinition>, ?defaultText:String)
    {
        super();

        this.id = 'haxefolio-normal-menu-$slug';
        this.text = MenuBuilderHelpers.resolveLabelText(defaultText, 'haxefolio.menubar.menu.$slug');
        this.addClass('haxefolio-normal-menu');
        this.verticalAlign = "center";

        for (item in items)
            this.addComponent(new NormalMenuItem(slug, item));
    }
}
