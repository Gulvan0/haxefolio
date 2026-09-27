package haxefolio.structure;

import morestd.Detachable;

/**
    A flag that stops the user from switching tabs, given to a `Tabs` region (see `Region`) - for a
    `Choose` region whose active form has a request in flight, where switching would either orphan
    the response or apply it to the wrong form. While `locked`, the strip ignores clicks and carries
    `.haxefolio-tab-strip-locked`; the selected tab stays selected.

    The host creates one, keeps the reference and flips `locked` itself.
**/
class TabLock
{
    private final handlers:Array<Bool->Void> = [];

    /**
        Whether the tabs are locked. Assigning the value it already has does nothing.
    **/
    public var locked(default, set):Bool;

    public function new(locked:Bool = false)
    {
        this.locked = locked;
    }

    /**
        Registers `handler` to run with the new value whenever `locked` changes. Returns the handle to
        detach it with. The tab strip registers itself this way, and releases it on disposal.
    **/
    public function onChange(handler:Bool->Void):Detachable
    {
        handlers.push(handler);
        return new Detachable(() -> handlers.remove(handler), false);
    }

    private function set_locked(value:Bool):Bool
    {
        if (locked == value)
            return value;

        locked = value;

        for (handler in handlers.copy())
            handler(value);

        return value;
    }
}
