package haxefolio.appearance;

import haxefolio.ByWidth;

/**
    `GeometryTokens` with every token optional - what a theme or a single overlay overrides.
    Tokens left out keep the value they would otherwise have.
**/
typedef PartialGeometryTokens = {
    ?headerHeight:ByWidth<Int>,
    ?actionBarHeight:ByWidth<Int>,
    ?tabStripHeight:ByWidth<Int>,
    ?searchBarHeight:ByWidth<Int>,
    ?fieldHeight:ByWidth<Int>,
    ?messageLine:Int,
    ?rowGap:Int,
    ?padding:Int
}
