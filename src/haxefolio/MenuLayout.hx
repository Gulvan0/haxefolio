package haxefolio;

/**
    The application-wide layout state (`ResponsivityController.menuLayout`), named after where the
    menu lives in it.
**/
enum MenuLayout
{
    /** The full menu bar on top: the viewport is at least `menuCollapseWidth` wide **/
    Expanded;

    /** The menu bar on top, reduced to the hamburger button and persistent widgets **/
    Collapsed;

    /**
        The collapsed menu bar turned into a strip along the left edge: the viewport is landscape
        and shorter than `menuRailHeight`, whatever its width
    **/
    Rail;
}
