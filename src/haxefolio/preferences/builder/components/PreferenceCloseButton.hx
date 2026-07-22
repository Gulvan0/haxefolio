package haxefolio.preferences.builder.components;

import haxe.ui.components.Image;

class PreferenceCloseButton extends Image
{
    public function new(onClick:Void->Void)
    {
        super();

        this.id = "haxefolio-preference-close-button";
        this.resource = "haxefolio/images/close_btn_icon.svg";
        this.addClass("haxefolio-preference-close-button");
        this.width = 14;
        this.height = 14;
        this.onClick = _ -> onClick();
    }
}
