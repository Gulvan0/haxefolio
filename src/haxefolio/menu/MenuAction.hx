package haxefolio.menu;

/**
    What happens when a menu bar item or sidebar entry using this action is clicked/activated.
**/
enum MenuAction
{
    /**
        Navigates to the path returned by `pathFactory`, via `HaxeFolioApp.navigateTo` - this goes
        through the same path-resolution and URL-updating mechanism as any other navigation,
        instead of bypassing the registered `PageDefinition`s.
    **/
    NavigateTo(pathFactory:Void->String);

    /**
        Runs `fn`. An item needing to navigate in a way `NavigateTo` doesn't cover (e.g. passing
        `state`/`fragment`) can still call `HaxeFolioApp.navigateTo` itself from here.
    **/
    Execute(fn:Void->Void);

    /**
        Opens `url` in a new tab if `newTab` is `true`, or the current one otherwise. Shorthand for
        an `Execute` whose callback opens `url` via `window.open` with the respective target.
    **/
    Link(url:String, newTab:Bool);
}
