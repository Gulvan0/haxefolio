package haxefolio.overlay;

import haxe.ui.containers.VBox;
import morestd.Detachable;

/*
    The shared, presentation-agnostic body of an overlay. A framework user builds their own by
    instantiating this directly (the same way PreferenceWindowBuilder.build does for the built-in
    preference window); whichever presentation tears the overlay down is responsible for calling
    dispose(), so detachables registered by the content don't outlive the overlay they were built
    for.
*/
class OverlayContent extends VBox
{
    private final detachables:Array<Detachable> = [];

    /**
        Registers `detachable` to be detached when this content's overlay is dismissed - typically
        a `Preference.onChange` handle or similar hook a piece of content's own setup registered.
    **/
    public function addDetachable(detachable:Detachable):Void
    {
        detachables.push(detachable);
    }

    /**
        Detaches every `Detachable` registered via `addDetachable`. Called by the framework once
        this content's overlay is dismissed - not intended to be called directly by a framework
        user.
    **/
    public function dispose():Void
    {
        for (detachable in detachables)
            detachable.detach();

        detachables.resize(0);
    }

    public function new()
    {
        super();
        percentWidth = 100;
        percentHeight = 100;
    }
}
