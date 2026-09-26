package haxefolio.preferences.builder;

import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.appearance.AppearanceContext;
import haxefolio.form.ChoiceGrid;
import haxefolio.form.ChoiceRow;
import haxefolio.form.FormSection;
import haxefolio.form.ToggleButton;
import haxefolio.form.plumbing.ChoiceOption;
import haxefolio.overlay.OverlayContent;
import haxefolio.structure.ActionBar;
import haxefolio.structure.ActionButton;
import haxefolio.structure.Region;
import haxefolio.structure.TabPage;
import morestd.Detachable;

/*
    Composes the preference window's content: a Header, a Navigate Tabs region with one page per
    preference tab, and an Actions footer holding Reset only (every control applies on change, so
    there is no Save - see "Preference window" in the manual).

    Which control a preference gets is decided here and nowhere else, by its kind and - for
    option/locale preferences - its value count:

    - toggle: ToggleButton
    - 2-4 values: ChoiceRow (stacked while the breakpoint is collapsed)
    - 5-20 values: ChoiceGrid
    - more: a design error, throws
*/
class PreferenceWindowBuilder
{
    private static inline final MAX_CHOICE_ROW_VALUES:Int = 4;
    private static inline final MAX_CHOICE_GRID_VALUES:Int = 20;

    public static function build(?tabIcons:Map<String, String>):OverlayContent
    {
        var detachables:Array<Detachable> = [];
        var pages:Array<TabPage> = [];

        for (group in PreferenceRegistry.getGroups())
        {
            var page:VBox = new VBox();
            page.percentWidth = 100;
            page.verticalSpacing = 0; // FormSection's own bottom margin is the only rhythm between preferences
            page.padding = AppearanceContext.current.geometry.padding;

            for (preference in group.preferences)
                page.addComponent(buildSection(preference, detachables));

            pages.push({
                label: LocaleUtils.localeBinding('haxefolio.preference.tab.${group.tabId}'),
                icon: tabIcons?.get(group.tabId),
                content: page
            });
        }

        var resetButton:ActionButton = new ActionButton(LocaleUtils.localeBinding("haxefolio.preference.reset"), PreferenceRegistry.resetAll);

        return {
            regions: [
                Header(LocaleUtils.localeBinding("haxefolio.preference.title")),
                Tabs(Navigate, pages),
                Actions(new ActionBar([resetButton]))
            ],
            onDismissed: () -> {
                for (detachable in detachables)
                    detachable.detach();
            }
        };
    }

    private static function buildSection(preference:Preference<Dynamic>, detachables:Array<Detachable>):Component
    {
        var name:String = LocaleUtils.localeBinding('haxefolio.preference.${preference.id}.name');

        switch preference.kind
        {
            case Toggle:
                var togglePreference:Preference<Bool> = cast preference;
                var toggle:ToggleButton = new ToggleButton(togglePreference.set, null, togglePreference.get());
                detachables.push(togglePreference.onChange(newValue -> toggle.on = newValue));

                return new FormSection(name, null, [toggle]);
            case Option:
                var optionPreference:Preference<String> = cast preference;
                var valueCount:Int = optionPreference.values.length;

                if (valueCount > MAX_CHOICE_GRID_VALUES)
                    throw 'Preference "${preference.id}" has $valueCount values; the preference window supports at most $MAX_CHOICE_GRID_VALUES';

                var options:Array<ChoiceOption<String>> = [
                    for (value in optionPreference.values)
                        {value: value, label: LocaleUtils.localeBinding('haxefolio.preference.${preference.id}.value.$value')}
                ];

                if (valueCount <= MAX_CHOICE_ROW_VALUES)
                {
                    var row:ChoiceRow<String> = new ChoiceRow(name, options, optionPreference.get(), optionPreference.set, {expanded: Horizontal, collapsed: Vertical});
                    detachables.push(optionPreference.onChange(row.select));
                    detachables.push(new Detachable(row.dispose));

                    return new FormSection(null, null, [row]);
                }

                var grid:ChoiceGrid<String> = new ChoiceGrid(name, options, Single(optionPreference.get(), optionPreference.set), {expanded: 4, collapsed: 2});
                detachables.push(optionPreference.onChange(grid.selectSingle));
                detachables.push(new Detachable(grid.dispose));

                return new FormSection(null, null, [grid]);
        }
    }
}
