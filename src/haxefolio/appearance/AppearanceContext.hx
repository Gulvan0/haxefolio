package haxefolio.appearance;

/**
    Holds the `Appearance` components read when they are built. Currently only the theme-wide one
    exists: it is the built-in default with `HaxeFolioConfig.appearance` applied over it by
    `HaxeFolioApp.init`. Reading it before that yields the built-in default.
**/
class AppearanceContext
{
    /**
        The appearance in effect.
    **/
    public static var current(default, null):Appearance = defaultAppearance();

    /**
        Replaces the theme-wide appearance with the built-in default overridden by `overrides`.
        Called once by `HaxeFolioApp.init`.
    **/
    public static function init(?overrides:AppearanceOverrides):Void
    {
        var base:Appearance = defaultAppearance();

        if (overrides == null)
        {
            current = base;
            return;
        }

        var geometry:GeometryTokens = base.geometry;
        var geometryOverrides:Null<PartialGeometryTokens> = overrides.geometry;

        if (geometryOverrides != null)
            geometry = {
                headerHeight: geometryOverrides.headerHeight ?? geometry.headerHeight,
                actionBarHeight: geometryOverrides.actionBarHeight ?? geometry.actionBarHeight,
                tabStripHeight: geometryOverrides.tabStripHeight ?? geometry.tabStripHeight,
                searchBarHeight: geometryOverrides.searchBarHeight ?? geometry.searchBarHeight,
                fieldHeight: geometryOverrides.fieldHeight ?? geometry.fieldHeight,
                messageLine: geometryOverrides.messageLine ?? geometry.messageLine,
                rowGap: geometryOverrides.rowGap ?? geometry.rowGap,
                padding: geometryOverrides.padding ?? geometry.padding
            };

        current = {
            geometry: geometry,
            emphasis: overrides.emphasis ?? base.emphasis
        };
    }

    private static function defaultAppearance():Appearance
    {
        return {
            geometry: {
                headerHeight: 60,
                actionBarHeight: 68,
                tabStripHeight: 44,
                searchBarHeight: 52,
                fieldHeight: 38,
                messageLine: 16,
                rowGap: 10,
                padding: 22
            },
            emphasis: Filled
        };
    }
}
