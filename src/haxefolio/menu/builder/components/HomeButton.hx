package haxefolio.menu.builder.components;

import haxe.ui.components.Button;

// a 44 x 44 target standing in for the site name: under the rail's hamburger button, and on a collapsed bar too narrow for the name
class HomeButton extends Button
{
    public function new(parent:String, icon:String, onClick:Void->Void)
    {
        super();

        this.id = 'haxefolio-home-button-$parent';
        this.addClass("haxefolio-home-button");
        this.verticalAlign = "center";
        this.icon = icon;
        this.onClick = _ -> onClick();
    }
}
