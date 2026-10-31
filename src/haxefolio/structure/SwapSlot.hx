package haxefolio.structure;

import haxe.ui.containers.Stack;
import haxe.ui.core.Component;
import js.Browser;

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

    The height may be reassigned later through the inherited `height` property - what lets an
    owner that computes it (e.g. a region stack sizing tab pages) push a new value in. Variants
    may also get heights of their own (`setVariantHeights`), still declared, never measured; the
    slot then animates between them on a switch by stepping `height` each frame, so whatever is
    laid out around the slot follows it instead of jumping at the start or the end.
*/
class SwapSlot<K> extends Stack
{
    private final keys:Array<K> = [];
    private var variantHeights:Null<Map<K, Int>> = null;
    private var transitionMs:Int = 0;
    private var transitionFrame:Null<Int> = null;

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

    /**
        Gives each variant its own height, `heights` holding one for every variant. The slot takes
        the active variant's at once; a later change of `active` animates to the new variant's over
        `transitionMs` (ease-out; at once with 0 or under `prefers-reduced-motion`). Calling it
        again, e.g. on a layout change, applies the new heights at once.
    **/
    public function setVariantHeights(heights:Map<K, Int>, transitionMs:Int = 0):Void
    {
        for (key in keys)
            if (!heights.exists(key))
                throw 'SwapSlot: no height given for $key';

        variantHeights = heights;
        this.transitionMs = transitionMs;
        stopTransition();
        this.height = heights.get(active);
    }

    private function set_active(value:K):K
    {
        var index:Int = keys.indexOf(value);
        if (index == -1)
            throw 'SwapSlot: no variant registered for $value';

        var changed:Bool = active != value;
        active = value;
        this.selectedIndex = index;

        if (variantHeights != null && changed)
            transitionTo(variantHeights.get(value));

        return value;
    }

    private function transitionTo(target:Int):Void
    {
        stopTransition();

        var start:Null<Float> = this.height;
        if (start == null || start == target || transitionMs <= 0 || prefersReducedMotion())
        {
            this.height = target;
            return;
        }

        var from:Float = start;
        var startedAt:Null<Float> = null;

        function step(now:Float):Void
        {
            if (startedAt == null)
                startedAt = now;

            var progress:Float = Math.min(1, (now - startedAt) / transitionMs);
            var eased:Float = 1 - (1 - progress) * (1 - progress);
            this.height = Math.round(from + (target - from) * eased);

            transitionFrame = progress < 1 ? Browser.window.requestAnimationFrame(step) : null;
        }

        transitionFrame = Browser.window.requestAnimationFrame(step);
    }

    private function stopTransition():Void
    {
        if (transitionFrame != null)
            Browser.window.cancelAnimationFrame(transitionFrame);
        transitionFrame = null;
    }

    private static function prefersReducedMotion():Bool
    {
        return Browser.window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    }
}
