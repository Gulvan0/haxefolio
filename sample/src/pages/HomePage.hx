package pages;

import haxe.ui.components.Label;
import haxefolio.PageBase;

class HomePage extends PageBase
{
    public function new()
    {
        super();
    }

    private override function init():Void
    {
        var label:Label = new Label();
        label.text = "Home page. Use the menu above to try the overlay demos, or navigate to About while one is open to see the navigation guard force-close it.";
        addComponent(label);
    }
}
