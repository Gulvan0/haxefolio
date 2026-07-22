package haxefolio.preferences.builder.components;

import haxe.ui.components.Button;

/*
    One admissible value of an option (or locale) preference, rendered as a button that is part of
    an exclusive-selection group (one button per preference id) via `toggle`/`componentGroup`.
*/
class OptionPreferenceButton extends Button
{
    public final optionValue:Dynamic;

    public function new(preferenceId:String, optionValue:Dynamic)
    {
        super();

        this.optionValue = optionValue;
        this.id = 'haxefolio-preference-option-button-$preferenceId-$optionValue';
        this.text = Utils.localeBinding('haxefolio.preference.$preferenceId.value.$optionValue');
        this.addClass("haxefolio-preference-option-button");
        this.toggle = true;
        this.componentGroup = preferenceId;
    }
}
