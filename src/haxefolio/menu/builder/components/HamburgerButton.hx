package haxefolio.menu.builder.components;

import haxe.ui.components.Button;

/*
    The 44 x 44 target at the start of the menu bar (opens the side bar) and of the side bar's
    header (closes it). The side bar's shows a cross instead of the three bars, in the same box, so
    the glyph says what the tap will do while the target itself never moves.
*/
class HamburgerButton extends Button
{
    public function new(parent:String, onClick:Void->Void, showsCross:Bool = false)
    {
        super();

        this.id = 'haxefolio-hamburger-button-$parent';
        this.addClass("haxefolio-hamburger-button");
        this.verticalAlign = "center";

        if (showsCross)
        {
            this.text = "✕";
            this.addClass("haxefolio-hamburger-button-cross");
        }
        else
            this.icon = "haxefolio/images/hamburger_btn_icon.svg";

        this.onClick = _ -> onClick();
    }
}
