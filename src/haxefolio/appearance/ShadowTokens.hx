package haxefolio.appearance;

import haxefolio.Shadow;

/**
    The elevation shadows of the framework's own floating surfaces. They live here rather than in a
    stylesheet because HaxeUI can't draw a shadow from one (see `ElementShadow`).
**/
typedef ShadowTokens =
{
    /** The dialog presentation's frame **/
    dialog:Shadow,
    /** The sheet presentation's panel, cast upward **/
    sheet:Shadow,
    /** The side bar, cast rightward **/
    sideBar:Shadow,
    menuDropdown:Shadow,
    notificationCard:Shadow
}
