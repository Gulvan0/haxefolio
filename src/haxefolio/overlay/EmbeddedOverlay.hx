package haxefolio.overlay;

import haxe.ui.core.Component;
import haxefolio.structure.RegionStack;
import morestd.Detachable;

/**
    The handle `HaxeFolioApp.embed` returns. `detach()` tears the embedded content down (once - later
    calls do nothing): its region stack is disposed, its frame removed from the host component and
    its own `onDismissed` hook run. Call it once the host is done with it, e.g. a page's `onClose`.

    Unlike a presented overlay, an embedded one has no presentation to size its frame, so the host
    owns the height: give it up front and change it through `frameHeight`.
**/
class EmbeddedOverlay extends Detachable
{
    private final frame:Component;
    private final stack:RegionStack;

    /**
        The height of the embedded frame. Assigning it recomputes the scrolling area's height and
        nothing else (see `RegionStack`).
    **/
    public var frameHeight(get, set):Float;

    public function new(frame:Component, stack:RegionStack, teardown:Void->Void)
    {
        super(teardown, false);

        this.frame = frame;
        this.stack = stack;
    }

    private function get_frameHeight():Float
    {
        return stack.frameHeight;
    }

    private function set_frameHeight(value:Float):Float
    {
        stack.frameHeight = value;
        frame.height = value;
        return value;
    }
}
