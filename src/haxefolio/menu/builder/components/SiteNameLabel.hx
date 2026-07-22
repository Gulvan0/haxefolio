package haxefolio.menu.builder.components;

import haxe.ui.components.Label;

class SiteNameLabel extends Label
{
    public function new(parent:String, siteName:String, onClick:Void->Void)
    {
        super();

        this.id = 'haxefolio-site-name-label-$parent';
        this.text = siteName;
        this.addClass("haxefolio-site-name-label");
        this.verticalAlign = "center";
        this.onClick = _ -> onClick();
    }
}
