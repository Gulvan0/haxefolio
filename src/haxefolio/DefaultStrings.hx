package haxefolio;

import haxe.ui.ToolkitAssets;
import haxe.ui.locale.LocaleManager;
import haxe.ui.parsers.locale.LocaleParser;

/** The framework's own English strings, shipped as a resource and registered by `module.xml`. **/
class DefaultStrings
{
    private static inline final RESOURCE_ID:String = "haxefolio/locale/en.properties";

    /**
        Gives each of `localeCodes` the English string for every framework key it lacks, since
        `LocaleManager` would otherwise display such a key raw. Requires `Toolkit.init` to have run.
    **/
    public static function fillMissing(localeCodes:Array<String>):Void
    {
        var strings:Map<String, String> = LocaleParser.get("properties").parse(ToolkitAssets.instance.getText(RESOURCE_ID));

        for (code in localeCodes)
        {
            var missing:Map<String, String> = [for (key => text in strings) if (LocaleManager.instance.translateTo(code, key) == key) key => text];
            LocaleManager.instance.addStrings(code, missing);

            #if debug
            if (missing.iterator().hasNext())
                trace('Locale "$code" lacks framework strings, using English: ${[for (key in missing.keys()) key].join(", ")}');
            #end
        }
    }
}
