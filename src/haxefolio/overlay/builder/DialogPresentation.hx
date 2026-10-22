package haxefolio.overlay.builder;

import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxefolio.ResponsivityController;
import haxefolio.Shadow;
import haxefolio.Viewport;
import haxefolio.structure.RegionStack;
import js.html.Element;

/*
    Expanded presentation: a centred window over a scrim covering the whole screen, menu bar
    included. Both are added to Screen.instance directly, so nothing of the page container is
    involved; making the rest of the app unreachable is OverlayController's job (it marks it inert).

    The frame has a fixed preferred size (the `dialogWidth`/`dialogHeight` tokens of the overlay's
    appearance), but tracks the viewport: a short or narrow viewport shrinks it - the height down
    to a floor below which it stops rather than becoming unusable - and only the stack's scrolling
    area notices (see RegionStack). A preferred height below the floor is its own floor. Deliberately not draggable, and
    there is no click-outside-to-dismiss: the scrim is inert.

    Presented over another overlay (`over`), the scrim covers only that overlay's frame, rounded to
    match, and the frame is centred on it rather than on the screen.

    Removed immediately by hide() - the only animation is the entry fade, which is a Web Animation
    on the DOM elements rather than a stylesheet animation, since it is purely presentational.
*/
class DialogPresentation extends OverlayPresentation
{
    private static inline var MINIMUM_HEIGHT:Int = 420;
    private static inline var VIEWPORT_MARGIN:Int = 32;
    private static inline var FADE_DURATION_MS:Int = 150;

    private final scrim:Box;
    private final frame:VBox;
    private final preferredWidth:Int;
    private final preferredHeight:Int;
    private final shadow:Shadow;
    private final over:Null<OverlayPresentation>;

    public function new(slug:String, stack:RegionStack, styleClass:Null<String>, preferredWidth:Int, preferredHeight:Int, shadow:Shadow, over:Null<OverlayPresentation>, onGone:Void->Void)
    {
        super(slug, stack, styleClass, onGone);

        this.preferredWidth = preferredWidth;
        this.preferredHeight = preferredHeight;
        this.shadow = shadow;
        this.over = over;

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
        ResponsivityController.markRoot(scrim);

        OverlayPresentation.styleFrameElement(frame.element, shadow);
        fadeIn(scrim.element);
        fadeIn(frame.element);
    }

    public override function hide():Void
    {
        Screen.instance.removeComponent(scrim, true);
        onGone();
    }

    public override function roots():Array<Component>
    {
        return [scrim];
    }

    public override function frameRect():{left:Float, top:Float, width:Float, height:Float}
    {
        return {left: frame.screenLeft, top: frame.screenTop, width: frame.width, height: frame.height};
    }

    public override function resize():Void
    {
        applySize();
    }

    private function applySize():Void
    {
        var covered:{left:Float, top:Float, width:Float, height:Float} = over != null ? over.frameRect() : {left: 0, top: 0, width: Viewport.width(), height: Viewport.height()};
        var width:Float = covered.width;
        var height:Float = covered.height;

        scrim.left = covered.left;
        scrim.top = covered.top;
        scrim.width = width;
        scrim.height = height;

        if (over != null)
            scrim.element.style.borderRadius = "9px";

        frame.width = Math.min(preferredWidth, width);
        stack.frameHeight = Math.max(Math.min(MINIMUM_HEIGHT, preferredHeight), Math.min(preferredHeight, height - 2 * VIEWPORT_MARGIN));
        frame.height = stack.frameHeight;
    }

    private static function fadeIn(element:Element):Void
    {
        (cast element : Dynamic).animate([{opacity: 0}, {opacity: 1}], FADE_DURATION_MS);
    }
}
