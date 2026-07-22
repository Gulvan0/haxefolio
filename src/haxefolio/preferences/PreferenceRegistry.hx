package haxefolio.preferences;

class PreferenceRegistry
{
    /*
        Tracks whether `locale` has already been called, so a framework user can't accidentally
        declare a second language preference. The preference itself is not tracked by identity here
        - a framework user wires the one they declared into HaxeFolioConfig.languagePreference
        explicitly, the same way every other piece of framework configuration is supplied.
    */
    private static var localePreferenceDeclared:Bool = false;

    private static final registeredIds:Map<String, Bool> = [];
    private static final allPreferences:Array<Preference<Dynamic>> = [];
    private static final pendingPreferences:Array<Preference<Dynamic>> = [];
    private static var backend:StorageBackend;

    /**
        Declares a boolean preference: assigns it to tab `tabId`, defaulting to `defaultValue`,
        and returns the typed `Preference<Bool>` field to assign to a static var. `id` must be
        unique across every preference declared in the app's `PreferenceRegistry` subclass, and
        the control rendered in the preference window is a slider.
    **/
    public static function toggle(tabId:String, id:String, defaultValue:Bool):Preference<Bool>
    {
        var preference:Preference<Bool> = new Preference(tabId, id, Toggle, defaultValue, value -> value ? "true" : "false", value -> value == "true");
        addPreference(preference);

        return preference;
    }

    /**
        Declares a string-valued preference restricted to `values`: assigns it to tab `tabId`,
        defaulting to `defaultValue`, and returns the typed `Preference<String>` field to assign
        to a static var. Throws if `defaultValue` is not among `values`. The control rendered in
        the preference window is a row of buttons, one per value.
    **/
    public static function option(tabId:String, id:String, values:Array<String>, defaultValue:String):Preference<String>
    {
        if (values.indexOf(defaultValue) == -1)
            throw 'Default value "$defaultValue" for option preference "$id" is not among its declared values: $values';

        var preference:Preference<String> = new Preference(tabId, id, Option, defaultValue, value -> value, value -> value, values);
        addPreference(preference);

        return preference;
    }

    /**
        Declares the language preference: an option-shaped preference whose admissible values are
        the app's `supportedLocales` rather than a caller-supplied list, since that list isn't
        known until `HaxeFolioApp.init` runs (well after this static field initializer does). Its
        values and default are filled in later, once `HaxeFolioApp.init` receives it via
        `HaxeFolioConfig.languagePreference` - passing it there is also what makes `HaxeFolioApp`
        wire it to `LocaleManager` and to active pages' title/blink text automatically, so the
        framework user never registers its update hook themselves. At most one may be declared.
    **/
    public static function locale(tabId:String, id:String):Preference<String>
    {
        if (localePreferenceDeclared)
            throw "A language preference has already been declared via PreferenceRegistry.locale; only one is allowed.";

        localePreferenceDeclared = true;

        var preference:Preference<String> = new Preference<String>(tabId, id, Option, null, value -> value, value -> value);
        addPreference(preference);

        return preference;
    }

    /**
        Calls `resetToDefault` on every declared preference, restoring each to its default value
        and triggering its `onChange` handlers.
    **/
    public static function resetAll():Void
    {
        for (preference in allPreferences)
            preference.resetToDefault();
    }

    /*
        Groups all declared preferences by tab id for the preference window builder, preserving
        both the order tabs were first encountered in and the declaration order of preferences
        within each tab.
    */
    public static function getGroups():Array<PreferenceGroup>
    {
        var groups:Array<PreferenceGroup> = [];
        var groupsByTabId:Map<String, PreferenceGroup> = [];

        for (preference in allPreferences)
        {
            var group:PreferenceGroup = groupsByTabId.get(preference.tabId);

            if (group == null)
            {
                group = {tabId: preference.tabId, preferences: []};
                groupsByTabId.set(preference.tabId, group);
                groups.push(group);
            }

            group.preferences.push(preference);
        }

        return groups;
    }

    /*
        Called by the framework during initialization, once the storage backend is
        available. Attaches it to every preference registered so far and flushes
        the buffer of preferences that were declared before this point.
    */
    public static function provideBackend(newBackend:StorageBackend):Void
    {
        backend = newBackend;

        for (preference in pendingPreferences)
            preference.bindBackend(backend);

        pendingPreferences.resize(0);
    }

    private static function addPreference(preference:Preference<Dynamic>):Void
    {
        if (registeredIds.exists(preference.id))
            throw 'Duplicate preference id: "${preference.id}"';

        registeredIds.set(preference.id, true);
        allPreferences.push(preference);

        if (backend != null)
            preference.bindBackend(backend);
        else
            pendingPreferences.push(preference);
    }
}
