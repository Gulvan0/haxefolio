package haxefolio.overlay.builder;

import haxe.ui.core.Component;
import haxefolio.Shadow;
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

    Presented over another overlay, it leaves a strip of `NESTED_TOP_INSET` pixels of that one visible
    above it.

    A fresh panel is built per overlay and disposed once gone.
*/
class SheetPresentation extends OverlayPresentation
{
    private final panel:EdgePanel;
    private static inline var NESTED_TOP_INSET:Int = 24;

    private final shadow:Shadow;
    private final nested:Bool;

    public function new(slug:String, stack:RegionStack, styleClass:Null<String>, shadow:Shadow, nested:Bool, onGone:Void->Void)
    {
        super(slug, stack, styleClass, onGone);

        this.shadow = shadow;
        this.nested = nested;

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

        OverlayPresentation.styleFrameElement(panel.element, shadow);
    }

    public override function hide():Void
    {
        panel.close();
    }

    public override function roots():Array<Component>
    {
        return [panel, panel.scrim];
    }

    public override function frameRect():{left:Float, top:Float, width:Float, height:Float}
    {
        return {left: panel.screenLeft, top: panel.screenTop, width: panel.width, height: panel.height};
    }

    public override function resize():Void
    {
        applySize();
    }

    private function applySize():Void
    {
        var width:Float = Viewport.width();
        var height:Float = Viewport.height() - (nested ? NESTED_TOP_INSET : 0);

        panel.width = width;
        stack.frameHeight = height;
        panel.height = height;
        panel.fit();
    }
}
