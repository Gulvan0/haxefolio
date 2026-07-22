package haxefolio;

import haxefolio.menu.MenuAction;
import haxefolio.menu.MenuBarItem;
import haxefolio.menu.MenuItemDefinition;
import haxefolio.menu.SidebarGroup;
import haxefolio.preferences.Preference;
import haxefolio.preferences.PreferenceRegistry;

/**
    Fluent, mutating alternative to constructing a `HaxeFolioConfig` anonymous structure directly.
    Every method mutates the builder in place and returns `this`; `add...` methods append,
    preserving call order as array order. Start a chain with `init` and terminate it with
    `buildConfig` to obtain the plain `HaxeFolioConfig` that `HaxeFolioApp.init` expects.
**/
class HaxeFolioConfigBuilder
{
    private var appSlug:String;
    private var appIcon:Null<String>;
    private var siteName:Null<String>;
    private var menuCollapseWidth:Int;
    private var pages:Array<PageDefinition>;
    private var menubarLeft:Array<MenuBarItem>;
    private var menubarRight:Array<MenuBarItem>;
    private var sidebarExtras:Array<SidebarGroup>;
    private var defaultTitleKey:Null<String>;
    private var supportedLocales:Null<Map<String, String>>;
    private var preferenceTabIcons:Null<Map<String, String>>;
    private var preferences:Class<PreferenceRegistry>;
    private var languagePreference:Null<Preference<String>>;

    private function new(appSlug:String, preferences:Class<PreferenceRegistry>)
    {
        this.appSlug = appSlug;
        this.preferences = preferences;
        menuCollapseWidth = 900;
        pages = [];
        menubarLeft = [];
        menubarRight = [];
        sidebarExtras = [];
    }

    /**
        Starts a new builder chain for an app identified by `appSlug` (see
        `HaxeFolioConfig.appSlug`), declaring `preferences` as its `PreferenceRegistry` subclass
        (see `HaxeFolioConfig.preferences`).
    **/
    public static function init(appSlug:String, preferences:Class<PreferenceRegistry>):HaxeFolioConfigBuilder
    {
        return new HaxeFolioConfigBuilder(appSlug, preferences);
    }

    public function setSiteName(siteName:String):HaxeFolioConfigBuilder
    {
        this.siteName = siteName;
        return this;
    }

    public function setAppIcon(appIcon:String):HaxeFolioConfigBuilder
    {
        this.appIcon = appIcon;
        return this;
    }

    public function setMenuCollapseWidth(menuCollapseWidth:Int):HaxeFolioConfigBuilder
    {
        this.menuCollapseWidth = menuCollapseWidth;
        return this;
    }

    public function addPage(path:String, factory:Map<String, String>->PageBase, ?isDefault:Bool):HaxeFolioConfigBuilder
    {
        pages.push({path: path, factory: factory, isDefault: isDefault});
        return this;
    }

    public function addLeftMenubarItem(item:MenuBarItem):HaxeFolioConfigBuilder
    {
        menubarLeft.push(item);
        return this;
    }

    public function addRightMenubarItem(item:MenuBarItem):HaxeFolioConfigBuilder
    {
        menubarRight.push(item);
        return this;
    }

    /**
        Appends an item to the `NormalMenu` identified by `menuSlug`. That menu must already have
        been added via `addLeftMenubarItem`/`addRightMenubarItem` - throws otherwise.
    **/
    public function addNormalMenuItem(menuSlug:String, itemSlug:String, action:MenuAction, ?icon:String):HaxeFolioConfigBuilder
    {
        findNormalMenuItems(menuSlug).push({slug: itemSlug, action: action, icon: icon});
        return this;
    }

    /**
        Appends an item to the sidebar-extras group identified by `groupSlug`, creating that group
        (in call order) if this is its first item.
    **/
    public function addSidebarExtraGroupItem(groupSlug:String, itemSlug:String, action:MenuAction, ?icon:String):HaxeFolioConfigBuilder
    {
        findOrCreateSidebarGroup(groupSlug).items.push({slug: itemSlug, action: action, icon: icon});
        return this;
    }

    public function setDefaultTitleKey(defaultTitleKey:String):HaxeFolioConfigBuilder
    {
        this.defaultTitleKey = defaultTitleKey;
        return this;
    }

    public function addLocale(code:String, displayName:String):HaxeFolioConfigBuilder
    {
        if (supportedLocales == null)
            supportedLocales = [];

        supportedLocales.set(code, displayName);
        return this;
    }

    public function setPreferenceTabIcons(tabIcons:Map<String, String>):HaxeFolioConfigBuilder
    {
        preferenceTabIcons = tabIcons;
        return this;
    }

    public function setLanguagePreference(languagePreference:Preference<String>):HaxeFolioConfigBuilder
    {
        this.languagePreference = languagePreference;
        return this;
    }

    /**
        Terminates the builder chain, producing the plain `HaxeFolioConfig` that `HaxeFolioApp.init`
        expects. Throws if `setAppIcon`/`setSiteName` were never called - both are required.
    **/
    public function buildConfig():HaxeFolioConfig
    {
        if (appIcon == null)
            throw "HaxeFolioConfigBuilder: appIcon must be set via setAppIcon before calling buildConfig.";

        if (siteName == null)
            throw "HaxeFolioConfigBuilder: siteName must be set via setSiteName before calling buildConfig.";

        return {
            appSlug: appSlug,
            appIcon: appIcon,
            siteName: siteName,
            menuCollapseWidth: menuCollapseWidth,
            pages: pages,
            menubar: {left: menubarLeft, right: menubarRight},
            sidebarExtras: sidebarExtras,
            defaultTitleKey: defaultTitleKey,
            supportedLocales: supportedLocales,
            preferenceTabIcons: preferenceTabIcons,
            preferences: preferences,
            languagePreference: languagePreference
        };
    }

    private function findNormalMenuItems(menuSlug:String):Array<MenuItemDefinition>
    {
        for (item in menubarLeft.concat(menubarRight))
            switch item
            {
                case NormalMenu(slug, items) if (slug == menuSlug):
                    return items;
                default:
            }

        throw 'HaxeFolioConfigBuilder: no NormalMenu with slug "$menuSlug" found in the left or right menu bar arrays. Add it first via addLeftMenubarItem/addRightMenubarItem.';
    }

    private function findOrCreateSidebarGroup(groupSlug:String):SidebarGroup
    {
        for (group in sidebarExtras)
            if (group.slug == groupSlug)
                return group;

        var group:SidebarGroup = {slug: groupSlug, items: []};
        sidebarExtras.push(group);
        return group;
    }
}
