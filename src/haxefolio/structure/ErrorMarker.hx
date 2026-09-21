package haxefolio.structure;

import morestd.Detachable;

/**
    A flag a container that can hide an invalid descendant (a tab page, and later a collapsible
    section or a wizard step) displays as an error marker, so that a blocked action is never left
    without a visible cause.

    The host creates one per container, keeps the reference and flips `active` from wherever it
    learns about validity - typically its fields' `onValidityChange`. Deciding what "invalid" means
    for a container holding several fields (any one of them) is the host's, not this class's.
**/
class ErrorMarker
{
    private final handlers:Array<Bool->Void> = [];

    /**
        Whether the container currently holds an invalid descendant. Assigning the value it already
        has does nothing.
    **/
    public var active(default, set):Bool;

    public function new(active:Bool = false)
    {
        this.active = active;
    }

    /**
        Registers `handler` to run with the new value whenever `active` changes. Returns the handle to
        detach it with. The displaying container registers itself this way, and releases it on disposal.
    **/
    public function onChange(handler:Bool->Void):Detachable
    {
        handlers.push(handler);
        return new Detachable(() -> handlers.remove(handler), false);
    }

    private function set_active(value:Bool):Bool
    {
        if (active == value)
            return value;

        active = value;

        for (handler in handlers.copy())
            handler(value);

        return value;
    }
}
