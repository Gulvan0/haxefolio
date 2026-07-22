package haxefolio.menu.builder.components;

import haxe.ui.components.Image;

class HamburgerButton extends Image
{
    public function new(parent:String, onClick:Void->Void)
    {
        super();

        this.id = 'haxefolio-hamburger-button-$parent';
        this.resource = "haxefolio/images/hamburger_btn_icon.svg";
        this.addClass("haxefolio-hamburger-button");
        this.width = 17;
        this.height = 15;
        this.verticalAlign = "center";
        this.onClick = _ -> onClick();
    }
}
