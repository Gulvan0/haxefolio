package haxefolio.preferences;

import js.Browser;

class StorageBackend
{
    private final appSlug:String;

    public function new(appSlug:String)
    {
        this.appSlug = appSlug;
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

    private function key(id:String):String
    {
        return '${Browser.window.location.hostname}.$appSlug.$id';
    }
}
