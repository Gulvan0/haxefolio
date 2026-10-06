package haxefolio.notification;

import haxe.ui.core.Component;

/**
    A notification on screen, as returned by `HaxeFolioApp.notify`. Its look is entirely its
    content's; the framework only places it (see `Notifications` in the manual).
**/
class Notification
{
    /**
        The component shown, as passed to `HaxeFolioApp.notify`.
    **/
    public final content:Component;

    /**
        The content's width while the breakpoint is expanded. While collapsed, every notification
        spans the viewport minus its margins instead.
    **/
    public final expandedWidth:Float;

    /**
        Whether the notification is still on screen, i.e. `dismiss` has not been called yet.
    **/
    public var isShown(default, null):Bool = true;

    @:allow(haxefolio.notification)
    private function new(content:Component, expandedWidth:Float)
    {
        this.content = content;
        this.expandedWidth = expandedWidth;
    }

    /**
        Takes the notification off screen. Its content is removed but not disposed, so it may be
        shown again by a later `HaxeFolioApp.notify`. Calling this more than once has no further
        effect.
    **/
    public function dismiss():Void
    {
        if (!isShown)
            return;

        isShown = false;
        NotificationLayer.remove(this);
    }
}
