package haxefolio.menu.builder.components;

import haxe.ui.containers.menus.MenuItem;

class NormalMenuItem extends MenuItem
{
    public function new(menuSlug:String, item:MenuItemDefinition)
    {
        super();

        this.id = 'haxefolio-normal-menu-$menuSlug-item-${item.slug}';
        this.text = Utils.localeBinding('haxefolio.menubar.menu.$menuSlug.item.${item.slug}');
        this.addClass('haxefolio-normal-menu-item');

        if (item.icon != null)
            this.icon = item.icon;

        this.onClick = _ -> MenuBuilderHelpers.invokeAction(item.action);
    }
}
