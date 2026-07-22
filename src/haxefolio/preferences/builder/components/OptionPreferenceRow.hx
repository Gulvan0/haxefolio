package haxefolio.preferences.builder.components;

import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxefolio.preferences.Preference;
import morestd.Detachable;

class OptionPreferenceRow extends HBox
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

        var buttonRow:HBox = new HBox();
        buttonRow.id = 'haxefolio-preference-option-row-${preference.id}';
        buttonRow.addClass("haxefolio-preference-option-row");
        buttonRow.verticalAlign = "center";

        var currentValue:Dynamic = preference.get();
        var buttons:Array<OptionPreferenceButton> = [];

        for (value in preference.values)
        {
            var button:OptionPreferenceButton = new OptionPreferenceButton(preference.id, value);
            button.selected = value == currentValue;
            buttons.push(button);
            buttonRow.addComponent(button);
        }

        for (button in buttons)
            button.onClick = _ -> {
                if (button.selected)
                    preference.set(button.optionValue);
            };

        this.detachable = preference.onChange(newValue -> {
            for (button in buttons)
                if (button.optionValue == newValue)
                    button.selected = true;
        });

        this.addComponent(buttonRow);
    }
}
