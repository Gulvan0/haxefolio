package haxefolio;

import haxe.ui.core.Component;
import morestd.Detachable;

/*
    Marks components `inert` on behalf of whatever is modal over them - an overlay
    (OverlayController) or the menu side bar - counting holds per component, so the attribute is
    only cleared once nothing holds it any more. Without the count, the side bar finishing its
    close would clear `inert` from the app while an overlay presented over it is still open,
    making that overlay non-modal.
*/
class InertHolds
{
    private static var holdCounts:Map<Component, Int> = [];

    /*
        Marks `components` inert until the returned handle is detached. Detaching more than once
        has no further effect.
    */
    @:allow(haxefolio)
    private static function hold(components:Array<Component>):Detachable
    {
        for (component in components)
        {
            var count:Int = holdCounts.exists(component) ? holdCounts.get(component) : 0;
            holdCounts.set(component, count + 1);

            if (count == 0)
                component.element.setAttribute("inert", "");
        }

        return new Detachable(() -> release(components), false);
    }

    private static function release(components:Array<Component>):Void
    {
        for (component in components)
        {
            var count:Int = holdCounts.get(component) - 1;

            if (count > 0)
            {
                holdCounts.set(component, count);
                continue;
            }

            holdCounts.remove(component);
            component.element.removeAttribute("inert");
        }
    }
}
