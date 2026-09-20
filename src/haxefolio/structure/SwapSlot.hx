package haxefolio.structure;

import haxe.ui.containers.Stack;
import haxe.ui.core.Component;

/*
    A fixed-height region that shows one of several variants. Built on HaxeUI's own `Stack`, not
    a from-scratch component - `Stack` already shows exactly one child at a time and, given an
    explicit height, already won't resize when the selection changes, since a hidden child is
    excluded from layout.

    The value added over a bare `Stack`: selection by an arbitrary key `K` (an enum, typically)
    instead of `Stack`'s own string id/int index, so a caller keying off a domain enum doesn't
    hand-rig an id-per-variant mapping; and `height` is a required constructor argument rather
    than merely possible, so the "constant height, never measured" contract is part of the type
    itself rather than a convention a bare `Stack` would let a caller forget. If a variant does
    not fit the supplied height, that is a design error to fix, not a case to accommodate.
*/
class SwapSlot<K> extends Stack
{
    private final keys:Array<K> = [];

    public var active(default, set):K;

    public function new(variants:Map<K, Component>, active:K, height:Int)
    {
        super();

        this.percentWidth = 100;
        this.height = height;
        this.addClass("haxefolio-swap-slot");

        for (key => component in variants)
        {
            keys.push(key);
            this.addComponent(component);
        }

        this.active = active;
    }

    private function set_active(value:K):K
    {
        var index:Int = keys.indexOf(value);
        if (index == -1)
            throw 'SwapSlot: no variant registered for $value';

        this.selectedIndex = index;
        return value;
    }
}
