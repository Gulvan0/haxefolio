package pages;

import haxe.ui.components.Label;
import haxefolio.PageBase;

class AboutPage extends PageBase
{
    public function new()
    {
        super();
    }

    private override function init():Void
    {
        var label:Label = new Label();
        label.text = "About page - just here as a navigation target for the overlay navigation-guard check.";
        addComponent(label);
    }
}
