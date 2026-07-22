package haxefolio.preferences.builder.components;

import haxe.ui.containers.VBox;
import haxefolio.preferences.Preference;
import haxefolio.preferences.PreferenceGroup;
import morestd.Detachable;

class PreferenceTabPage extends VBox
{
    public final detachables:Array<Detachable> = [];

    public function new(group:PreferenceGroup, ?icon:String)
    {
        super();

        this.id = 'haxefolio-preference-tab-${group.tabId}';
        this.text = Utils.localeBinding('haxefolio.preference.tab.${group.tabId}');
        this.addClass("haxefolio-preference-tab");
        this.percentWidth = 100;

        if (icon != null)
            this.icon = icon;

        for (preference in group.preferences)
            buildRow(preference);
    }

    private function buildRow(preference:Preference<Dynamic>):Void
    {
        switch preference.kind
        {
            case Toggle:
                var row:TogglePreferenceRow = new TogglePreferenceRow(preference);
                detachables.push(row.detachable);
                this.addComponent(row);
            case Option:
                var row:OptionPreferenceRow = new OptionPreferenceRow(preference);
                detachables.push(row.detachable);
                this.addComponent(row);
        }
    }
}
