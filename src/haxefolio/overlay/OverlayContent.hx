package haxefolio.overlay;

import haxefolio.structure.Region;

/**
    What an overlay is made of: a title and the ordered regions the overlay's frame holds (see
    `RegionStack`). Built by the content factories given to `HaxeFolioApp.present`.
**/
typedef OverlayContent = {
    /**
        The overlay's title. Shown by the `Header` region once it exists; until then, no region reads it.
    **/
    title:String,

    /**
        The regions the frame holds, top to bottom. At most one may be a `Scroll` region.
    **/
    regions:Array<Region>,

    /**
        The content's own teardown hook: whatever the content registered while it was built - a
        `Preference.onChange` handle, a `ChoiceGrid` breakpoint binding - is released here. Called
        exactly once, when the overlay is gone, before the `onDismissed` argument of `present`
        (which belongs to the host that called `present`, not to the content).
    **/
    ?onDismissed:Void->Void
}
