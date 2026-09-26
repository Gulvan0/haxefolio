package haxefolio.overlay.builder;

import haxefolio.Viewport;
import haxefolio.structure.EdgePanel;
import haxefolio.structure.RegionStack;

/*
    Collapsed presentation: an EdgePanel sliding up from the bottom, covering the entire viewport
    (menu bar included). The page container underneath is left alone - the page keeps running and
    is never destroyed; navigation state and the URL are untouched too.

    Fully exclusive: the panel's scrim covers the screen for the entire show -> gone window
    (opening, open and closing), so nothing beneath the sheet is reachable at any point - not even
    the not-yet-covered sliver of screen mid-slide. It carries no dismiss handler: there is no
    click-outside-to-dismiss. (The sheet itself covers the whole viewport once open, so the scrim is
    only ever visible mid-slide.)

    A fresh panel is built per overlay and disposed once gone.
*/
class SheetPresentation extends OverlayPresentation
{
    private final panel:EdgePanel;

    public function new(slug:String, stack:RegionStack, styleClass:Null<String>, onGone:Void->Void)
    {
        super(slug, stack, styleClass, onGone);

        panel = new EdgePanel(Bottom, onGone, null, true);
        panel.id = 'haxefolio-overlay-$slug-frame';
        panel.addClass("haxefolio-overlay-frame");
        panel.addClass("haxefolio-overlay-sheet");

        panel.scrim.id = 'haxefolio-overlay-$slug-scrim';
        panel.scrim.addClass("haxefolio-overlay-scrim");
        panel.scrim.addClass("haxefolio-overlay-sheet-scrim");

        // on the frame only: a variant's own colours must not paint over the scrim
        if (styleClass != null)
            panel.addClass(styleClass);

        panel.addComponent(stack);

        applySize();
    }

    public override function show():Void
    {
        panel.open();

        OverlayPresentation.styleFrameElement(panel.element, "0 -4px 20px rgba(24, 26, 31, 0.18)");
    }

    public override function hide():Void
    {
        panel.close();
    }

    public override function resize():Void
    {
        applySize();
    }

    private function applySize():Void
    {
        var width:Float = Viewport.width();
        var height:Float = Viewport.height();

        panel.width = width;
        stack.frameHeight = height;
        panel.height = height;
        panel.fit();
    }
}
