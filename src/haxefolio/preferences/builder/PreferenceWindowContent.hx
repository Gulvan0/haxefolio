package haxefolio.preferences.builder;

import haxe.ui.containers.VBox;
import morestd.Detachable;

/*
    The shared, presentation-agnostic body of the preference panel (tabs + reset button). A fresh
    instance is built by PreferenceWindowBuilder every time a presenter shows the panel; whichever
    presenter tears it down is responsible for calling dispose(), so the preference onChange hooks
    registered by its rows don't outlive the panel they were built for.
*/
class PreferenceWindowContent extends VBox
{
    private final detachables:Array<Detachable> = [];

    public function addDetachable(detachable:Detachable):Void
    {
        detachables.push(detachable);
    }

    public function dispose():Void
    {
        for (detachable in detachables)
            detachable.detach();

        detachables.resize(0);
    }
}
