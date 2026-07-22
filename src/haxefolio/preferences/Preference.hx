package haxefolio.preferences;

import morestd.Detachable;

class Preference<T>
{
    public final tabId:String;
    public final id:String;
    public final kind:PreferenceKind;
    public var defaultValue(default, null):T;
    public var values(default, null):Null<Array<T>>;

    private var value:T;
    private var backend:StorageBackend;
    private final serialize:T->String;
    private final deserialize:String->T;
    private final hooks:Array<T->Void>;

    public function new(tabId:String, id:String, kind:PreferenceKind, defaultValue:T, serialize:T->String, deserialize:String->T, ?values:Array<T>)
    {
        this.tabId = tabId;
        this.id = id;
        this.kind = kind;
        this.defaultValue = defaultValue;
        this.serialize = serialize;
        this.deserialize = deserialize;
        this.value = defaultValue;
        this.hooks = [];
        this.values = values;
    }

    /**
        Returns the preference's current in-memory value.
    **/
    public function get():T
    {
        return value;
    }

    /**
        Writes `value` to memory and LocalStorage, then triggers every handler registered via
        `onChange`.
    **/
    public function set(value:T):Void
    {
        setQuiet(value);

        for (hook in hooks)
            hook(value);
    }

    /**
        Writes `value` to memory and LocalStorage without triggering `onChange` handlers. Intended
        for cases where the value is updated programmatically and reactive handlers should not
        fire.
    **/
    public function setQuiet(value:T):Void
    {
        this.value = value;

        if (backend != null)
            backend.write(id, serialize(value));
    }

    /**
        Equivalent to `set(defaultValue)` - writes the declared default and triggers `onChange`
        handlers.
    **/
    public function resetToDefault():Void
    {
        set(defaultValue);
    }

    /**
        Registers `handler` to run every time this preference's value changes via `set` or
        `resetToDefault` (not `setQuiet`). Multiple handlers may be registered for the same
        preference. Returns a `Detachable` used to unregister the handler later - the canonical
        pattern for page components is to register in `init` and detach in `onClose`.
    **/
    public function onChange(handler:T->Void):Detachable
    {
        hooks.push(handler);

        return new Detachable(() -> hooks.remove(handler));
    }

    /*
        Called by PreferenceRegistry once the storage backend becomes available, to load
        the persisted value (or fall back to the default) and enable subsequent writes.
    */
    public function bindBackend(backend:StorageBackend):Void
    {
        this.backend = backend;

        var storedValue:Null<String> = backend.read(id);
        this.value = storedValue != null ? deserialize(storedValue) : defaultValue;
    }

    /*
        Called by HaxeFolioApp, once HaxeFolioConfig (and hence the supported locale list) is
        available, to retroactively supply the admissible values and default for a language
        preference declared via PreferenceRegistry.locale - neither is known yet at the point
        such a preference is constructed, during the user's PreferenceRegistry subclass's static
        field initialization. Must be called before bindBackend, since bindBackend falls back to
        whatever defaultValue currently holds. Restricted to HaxeFolioApp since calling this on a
        preference outside that one-time handshake would silently discard its declared values.
    */
    @:allow(haxefolio.HaxeFolioApp)
    private function finalizeAdmissibleValues(values:Array<T>, defaultValue:T):Void
    {
        if (values.indexOf(defaultValue) == -1)
            throw 'Default value "$defaultValue" for preference "$id" is not among its declared values: $values';

        this.values = values;
        this.defaultValue = defaultValue;
    }
}
