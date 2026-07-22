package haxefolio.preferences.builder.components;

import haxe.ui.components.Label;
import haxe.ui.components.Switch;
import haxe.ui.containers.HBox;
import haxefolio.preferences.Preference;
import morestd.Detachable;

class TogglePreferenceRow extends HBox
{
    public final detachable:Detachable;

    public function new(preference:Preference<Dynamic>)
    {
        super();

        this.id = 'haxefolio-preference-row-${preference.id}';
        this.addClass("haxefolio-preference-row");
        this.percentWidth = 100;

        var nameLabel:Label = new Label();
        nameLabel.id = 'haxefolio-preference-name-label-${preference.id}';
        nameLabel.text = Utils.localeBinding('haxefolio.preference.${preference.id}.name');
        nameLabel.addClass("haxefolio-preference-name-label");
        nameLabel.textAlign = "center";
        nameLabel.verticalAlign = "center";
        this.addComponent(nameLabel);

        var toggleSwitch:Switch = new Switch();
        toggleSwitch.id = 'haxefolio-preference-switch-${preference.id}';
        toggleSwitch.addClasses(["haxefolio-preference-toggle", "pill-switch"]);
        toggleSwitch.selected = preference.get();
        toggleSwitch.verticalAlign = "center";
        toggleSwitch.onChange = _ -> preference.set(toggleSwitch.selected);
        this.detachable = preference.onChange(newValue -> toggleSwitch.selected = newValue);
        this.addComponent(toggleSwitch);
    }
}
