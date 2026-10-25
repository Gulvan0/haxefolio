package haxefolio.appearance;

import haxefolio.ByMenuLayout;

/**
    `GeometryTokens` with every token optional - what a theme or a single overlay overrides.
    Tokens left out keep the value they would otherwise have.
**/
typedef PartialGeometryTokens = {
    ?headerHeight:ByMenuLayout<Int>,
    ?actionBarHeight:ByMenuLayout<Int>,
    ?tabStripHeight:ByMenuLayout<Int>,
    ?searchBarHeight:ByMenuLayout<Int>,
    ?fieldHeight:ByMenuLayout<Int>,
    ?messageLine:Int,
    ?rowGap:Int,
    ?padding:Int,
    ?dialogWidth:Int,
    ?dialogHeight:Int
}
