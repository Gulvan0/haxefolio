package haxefolio.appearance;

import haxefolio.Shadow;

/**
    `ShadowTokens` with every token optional - what a theme or a single overlay overrides. Tokens
    left out keep the value they would otherwise have.
**/
typedef PartialShadowTokens =
{
    ?dialog:Shadow,
    ?sheet:Shadow,
    ?sideBar:Shadow,
    ?menuDropdown:Shadow,
    ?notificationCard:Shadow
}
