package overlay;

import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.form.ChoiceRow;
import haxefolio.overlay.OverlayContent;
import haxefolio.structure.Region;
import js.Browser;

/*
    Builder functions for the sample's own overlay content, each returning a fresh OverlayContent
    the way a real framework user's own content would be. Until the Header and Actions regions
    exist, a "footer" is a Custom region the sample fills itself.
*/
class CustomOverlayContent
{
    private static inline var FOOTER_HEIGHT:Int = 68;

    public static function buildPlain():OverlayContent
    {
        return {
            title: "Plain overlay",
            regions: [Scroll(body([label("A plain overlay: one Scroll region, everything else left to the presentation. Press Esc to close it.")]))]
        };
    }

    public static function buildDismissible(dismiss:Void->Void):OverlayContent
    {
        return {
            title: "Dismissible",
            regions: [
                Scroll(body([label("The footer's button closes the overlay through the dismiss handle its factory received. Esc works too.")])),
                footer(dismiss)
            ]
        };
    }

    public static function buildDesktopVariant():OverlayContent
    {
        var row:HBox = new HBox();
        row.addComponent(label("Expanded column A"));
        row.addComponent(label("Expanded column B"));

        return {
            title: "Mobile variant",
            regions: [Scroll(body([row]))]
        };
    }

    public static function buildMobileVariant():OverlayContent
    {
        return {
            title: "Mobile variant",
            regions: [Scroll(body([label("Collapsed content - a genuinely different component tree from the expanded variant of this overlay.")]))]
        };
    }

    /*
        Content much taller than any frame, with a footer: only the scrolling area may move, and
        the footer must stay put whatever the viewport does. Its teardown hook logs to the console,
        which is how the "called exactly once, when the overlay is gone" contract is checked.
    */
    public static function buildLong(dismiss:Void->Void):OverlayContent
    {
        var lines:Array<Component> = [for (i in 1...41) label('Line $i of 40 - scroll to the end; scrolling must stop there instead of moving the page behind.')];

        return {
            title: "Long content",
            regions: [Scroll(body(lines)), footer(dismiss)],
            onDismissed: () -> Browser.console.log("[overlay-demo] content.onDismissed")
        };
    }

    /*
        Built under a per-overlay appearance (Outlined emphasis, plus a style class): the selected
        choice below must be drawn tinted-and-bordered rather than as a solid fill.
    */
    public static function buildAppearance():OverlayContent
    {
        var row:ChoiceRow<String> = new ChoiceRow("Emphasis follows the overlay", [
            {value: "a", label: "First"},
            {value: "b", label: "Second"}
        ], "a", _ -> {});

        return {
            title: "Appearance override",
            regions: [Scroll(body([label("This overlay overrides emphasis and carries a style class (tinted frame)."), row]))],
            onDismissed: row.dispose
        };
    }

    private static function label(text:String):Label
    {
        var result:Label = new Label();
        result.percentWidth = 100;
        result.text = text;
        result.addClass("haxefolio-label");
        return result;
    }

    private static function body(children:Array<Component>):Component
    {
        var result:VBox = new VBox();
        result.percentWidth = 100;
        result.addClass("sample-overlay-body");

        for (child in children)
            result.addComponent(child);

        return result;
    }

    private static function footer(dismiss:Void->Void):Region
    {
        var closeButton:Button = new Button();
        closeButton.text = "Save & Close";
        closeButton.addClass("haxefolio-button");
        closeButton.onClick = _ -> dismiss();

        var bar:Box = new Box();
        bar.percentWidth = 100;
        bar.percentHeight = 100;
        bar.addClass("sample-overlay-footer");
        bar.addComponent(closeButton);

        return Custom(FOOTER_HEIGHT, bar);
    }
}
