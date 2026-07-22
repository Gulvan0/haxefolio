package haxefolio.preferences.builder.components;

import haxe.ui.components.Button;
import haxefolio.preferences.PreferenceRegistry;

class PreferenceResetButton extends Button
{
    public function new()
    {
        super();

        this.id = "haxefolio-preference-reset-button";
        this.text = Utils.localeBinding("haxefolio.preference.reset");
        this.addClass("haxefolio-preference-reset-button");
        this.onClick = _ -> PreferenceRegistry.resetAll();
    }
}
