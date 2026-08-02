package haxefolio.preferences;

import js.Browser;
import js.html.StorageEvent;
import morestd.StringSetMap;

using StringTools;

class StorageBackend
{
    private final appSlug:String;
    private var changeListeners:StringSetMap<Null<String>->Void> = new StringSetMap();

    public function new(appSlug:String)
    {
        this.appSlug = appSlug;
        Browser.window.addEventListener("storage", onNativeStorageEvent);
    }

    public function has(id:String):Bool
    {
        return read(id) != null;
    }

    public function read(id:String):Null<String>
    {
        return Browser.window.localStorage.getItem(key(id));
    }

    public function write(id:String, value:String):Void
    {
        Browser.window.localStorage.setItem(key(id), value);
    }

    public function remove(id:String):Void
    {
        Browser.window.localStorage.removeItem(key(id));
    }

    /**
        Registers `callback` to run whenever `id` (as passed to `read`/`write`) changes in
        `localStorage` from ANOTHER same-origin tab/window - per the DOM `storage` event spec, this
        never fires for changes made by the current tab itself (browsers only dispatch it to
        *other* browsing contexts), so no same-tab feedback loop is possible. `callback` receives
        the new raw string value (`null` if the key was removed). Multiple distinct callbacks may
        be registered for the same `id`; all run once per matching native event (registration
        order is not guaranteed, since `StringSetMap` backs each `id` with a `Set`).
    **/
    public function addExternalChangeHandler(id:String, callback:Null<String>->Void):Void
    {
        changeListeners.add(id, callback);
    }

    private function onNativeStorageEvent(event:StorageEvent):Void
    {
        var keyPrefix:String = '$appSlug.';

        if (event.storageArea != Browser.window.localStorage)
            return;
        if (event.key == null)
            return; // fired by localStorage.clear(); out of scope
        if (!event.key.startsWith(keyPrefix))
            return;

        var id:String = event.key.substr(keyPrefix.length);

        for (listener in changeListeners.get(id))
            listener(event.newValue);
    }

    private function key(id:String):String
    {
        return '$appSlug.$id';
    }
}
