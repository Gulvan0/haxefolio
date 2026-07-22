package haxefolio.preferences.builder.components;

import haxe.ui.components.Label;

/*
    Balances the footer row out against the reset button on the other end - fills whatever width
    the button doesn't take up and right-aligns its own text within that, rather than sitting
    immediately next to the button.
*/
class PreferenceAutosaveNoticeLabel extends Label
{
    public function new()
    {
        super();

        this.id = "haxefolio-preference-autosave-notice";
        this.text = Utils.localeBinding("haxefolio.preference.autosave_notice");
        this.addClass("haxefolio-preference-autosave-notice");
        this.percentWidth = 100;
        this.textAlign = "right";
        this.verticalAlign = "center";
    }
}
