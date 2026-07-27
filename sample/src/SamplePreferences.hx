package;

import haxefolio.preferences.PreferenceRegistry;

class SamplePreferences extends PreferenceRegistry
{
    public static final language = PreferenceRegistry.locale("general", "language");
    public static final compactMode = PreferenceRegistry.toggle("general", "compact_mode", false);
    public static final theme = PreferenceRegistry.option("general", "theme", ["light", "dark"], "light");
}
