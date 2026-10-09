package haxefolio.appearance;

/**
    Holds the `Appearance` components read when they are built: the theme-wide one - the built-in
    default with `HaxeFolioConfig.appearance` applied over it by `HaxeFolioApp.init` - or, while an
    overlay's content is being built, that overlay's own (see `runWith`). Reading it before `init`
    yields the built-in default.
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
        current = merge(defaultAppearance(), overrides);
    }

    /**
        Runs `build` with `current` temporarily replaced by the appearance in effect overridden by
        `overrides`, so every component `build` constructs reads that appearance. Used to give one
        overlay its own geometry/emphasis while its content is built; `current` is restored
        afterwards, even if `build` throws.
    **/
    public static function runWith<T>(?overrides:AppearanceOverrides, build:Void->T):T
    {
        var previous:Appearance = current;
        current = merge(previous, overrides);

        try
        {
            var result:T = build();
            current = previous;
            return result;
        }
        catch (e:Dynamic)
        {
            current = previous;
            throw e;
        }
    }

    private static function merge(base:Appearance, ?overrides:AppearanceOverrides):Appearance
    {
        if (overrides == null)
            return base;

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
                padding: geometryOverrides.padding ?? geometry.padding,
                dialogWidth: geometryOverrides.dialogWidth ?? geometry.dialogWidth,
                dialogHeight: geometryOverrides.dialogHeight ?? geometry.dialogHeight
            };

        var shadows:ShadowTokens = base.shadows;
        var shadowOverrides:Null<PartialShadowTokens> = overrides.shadows;

        if (shadowOverrides != null)
            shadows = {
                dialog: shadowOverrides.dialog ?? shadows.dialog,
                sheet: shadowOverrides.sheet ?? shadows.sheet,
                sideBar: shadowOverrides.sideBar ?? shadows.sideBar,
                menuDropdown: shadowOverrides.menuDropdown ?? shadows.menuDropdown,
                notificationCard: shadowOverrides.notificationCard ?? shadows.notificationCard
            };

        return {
            geometry: geometry,
            shadows: shadows,
            selectionEmphasis: overrides.selectionEmphasis ?? base.selectionEmphasis,
            actionEmphasis: overrides.actionEmphasis ?? base.actionEmphasis
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
                padding: 22,
                dialogWidth: 620,
                dialogHeight: 720
            },
            shadows: {
                dialog: {offsetX: 0, offsetY: 8, blur: 28, color: 0x181A1F, opacity: 0.16},
                sheet: {offsetX: 0, offsetY: -4, blur: 20, color: 0x181A1F, opacity: 0.18},
                sideBar: {offsetX: 4, offsetY: 0, blur: 20, color: 0x181A1F, opacity: 0.18},
                menuDropdown: {offsetX: 0, offsetY: 8, blur: 28, color: 0x181A1F, opacity: 0.16},
                notificationCard: {offsetX: 0, offsetY: 8, blur: 28, color: 0x181A1F, opacity: 0.16}
            },
            selectionEmphasis: Filled,
            actionEmphasis: Filled
        };
    }
}
