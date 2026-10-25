package haxefolio.menu;

import haxe.ui.components.Button;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.menu.builder.MenuBuilderHelpers;

/**
    A dropdown widget whose dropdown is a menu: an optional header over a row per
    `MenuItemDefinition`, the rows looking like a `NormalMenu`'s items. A row closes the dropdown
    and runs its action. Absent `defaultText`, a row's label is the
    `haxefolio.menubar.menu.<slug>.item.<item slug>` locale key, the same as a `NormalMenu` item's.
**/
class MenuDropdownWidget extends DropdownWidget
{
    private final list:VBox;
    private final headerSlot:Box;
    private final divider:Component;
    private final rows:Map<String, Button> = [];

    public function new(targetIcon:Component, slug:String, items:Array<MenuItemDefinition>, frameWidth:Float)
    {
        super(targetIcon, new VBox(), frameWidth); // named apart from the superclass constructor's: HaxeUI stores each in a field

        list = cast content;
        list.addClass("haxefolio-dropdown-menu");

        headerSlot = new Box();
        headerSlot.percentWidth = 100;
        headerSlot.hidden = true;
        list.addComponent(headerSlot);

        divider = new Component();
        divider.addClass("haxefolio-dropdown-menu-divider");
        divider.percentWidth = 100;
        divider.hidden = true;
        list.addComponent(divider);

        for (item in items)
        {
            var row:Button = buildRow(slug, item);
            rows.set(item.slug, row);
            list.addComponent(row);
        }
    }

    /** Shows `component` above the rows, over a divider; null removes the current one, disposing it **/
    public function setHeader(component:Null<Component>):Void
    {
        headerSlot.removeAllComponents(true);
        headerSlot.hidden = component == null;
        divider.hidden = component == null;

        if (component != null)
            headerSlot.addComponent(component);
    }

    /** Throws if there is no row for `itemSlug` **/
    public function setItemHidden(itemSlug:String, hidden:Bool):Void
    {
        var row:Null<Button> = rows.get(itemSlug);
        if (row == null)
            throw 'No dropdown menu item "$itemSlug"';

        row.hidden = hidden;
    }

    private function buildRow(slug:String, item:MenuItemDefinition):Button
    {
        var row:Button = new Button();
        row.id = 'haxefolio-dropdown-menu-$slug-item-${item.slug}';
        row.text = MenuBuilderHelpers.resolveLabelText(item.defaultText, 'haxefolio.menubar.menu.$slug.item.${item.slug}');
        row.addClass("haxefolio-dropdown-menu-item");
        row.percentWidth = 100;
        row.hidden = item.hiddenByDefault == true;

        if (item.icon != null)
            row.icon = item.icon;

        row.onClick = _ -> {
            close();
            MenuBuilderHelpers.invokeAction(item.action);
        };

        return row;
    }
}
