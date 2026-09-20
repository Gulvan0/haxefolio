package haxefolio.overlay.builder;

import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxe.ui.core.Screen;
import haxefolio.structure.RegionStack;
import js.html.Element;

/*
    Expanded presentation: a centred window over a scrim covering the whole screen, menu bar
    included. Both are added to Screen.instance directly, so nothing of the page container is
    involved; making the rest of the app unreachable is OverlayController's job (it marks it inert).

    The frame has a fixed preferred size, but tracks the viewport: a short or narrow viewport
    shrinks it - the height down to a floor below which it stops rather than becoming unusable -
    and only the stack's scrolling area notices (see RegionStack). Deliberately not draggable, and
    there is no click-outside-to-dismiss: the scrim is inert.

    Removed immediately by hide() - the only animation is the entry fade, which is a Web Animation
    on the DOM elements rather than a stylesheet animation, since it is purely presentational.
*/
class DialogPresentation extends OverlayPresentation
{
    private static inline var PREFERRED_WIDTH:Int = 620;
    private static inline var PREFERRED_HEIGHT:Int = 720;
    private static inline var MINIMUM_HEIGHT:Int = 420;
    private static inline var VIEWPORT_MARGIN:Int = 32;
    private static inline var FADE_DURATION_MS:Int = 150;

    private final scrim:Box;
    private final frame:VBox;

    public function new(slug:String, stack:RegionStack, styleClass:Null<String>, onGone:Void->Void)
    {
        super(slug, stack, styleClass, onGone);

        scrim = new Box();
        scrim.id = 'haxefolio-overlay-$slug-scrim';
        scrim.addClass("haxefolio-overlay-scrim");
        scrim.addClass("haxefolio-overlay-dialog-scrim");

        frame = new VBox();
        frame.id = 'haxefolio-overlay-$slug-frame';
        frame.addClass("haxefolio-overlay-frame");
        frame.addClass("haxefolio-overlay-dialog");
        frame.horizontalAlign = "center";
        frame.verticalAlign = "center";

        // on the frame only: a variant's own colours must not paint over the scrim
        if (styleClass != null)
            frame.addClass(styleClass);

        frame.addComponent(stack);
        scrim.addComponent(frame);

        applySize();
    }

    public override function show():Void
    {
        Screen.instance.addComponent(scrim);

        OverlayPresentation.styleFrameElement(frame.element, "0 8px 28px rgba(24, 26, 31, 0.16)");
        fadeIn(scrim.element);
        fadeIn(frame.element);
    }

    public override function hide():Void
    {
        Screen.instance.removeComponent(scrim, true);
        onGone();
    }

    public override function resize():Void
    {
        applySize();
    }

    private function applySize():Void
    {
        var width:Float = OverlayPresentation.viewportWidth();
        var height:Float = OverlayPresentation.viewportHeight();

        scrim.width = width;
        scrim.height = height;

        frame.width = Math.min(PREFERRED_WIDTH, width);
        stack.frameHeight = Math.max(MINIMUM_HEIGHT, Math.min(PREFERRED_HEIGHT, height - 2 * VIEWPORT_MARGIN));
        frame.height = stack.frameHeight;
    }

    private static function fadeIn(element:Element):Void
    {
        (cast element : Dynamic).animate([{opacity: 0}, {opacity: 1}], FADE_DURATION_MS);
    }
}
