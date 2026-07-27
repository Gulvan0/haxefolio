package haxefolio.overlay.builder.components;

import haxe.ui.components.Image;

/*
    The default icon (and 14px/14px size) are not set here - they live on the generic
    `.haxefolio-overlay-close-button` CSS class in main.css instead, so a framework user can
    override either for a single overlay (via its `#haxefolio-overlay-<slug>-close-button` id) or
    for every overlay at once (via the class) without any new Haxe API surface. `size` is therefore
    only applied when explicitly given, rather than defaulting to 14 here.
*/
class OverlayCloseButton extends Image
{
    public function new(id:String, onClick:Void->Void, ?size:Int)
    {
        super();

        this.id = id;
        this.addClass("haxefolio-overlay-close-button");

        if (size != null)
        {
            this.width = size;
            this.height = size;
        }

        this.onClick = _ -> onClick();
    }
}
