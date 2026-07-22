package haxefolio.preferences;

// One preference window tab's worth of preferences, in declaration order.
typedef PreferenceGroup = {
    tabId:String,
    preferences:Array<Preference<Dynamic>>
}
