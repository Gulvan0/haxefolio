package pages;

import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.layouts.VerticalLayout;
import haxefolio.HaxeFolioApp;
import haxefolio.PageBase;
import haxefolio.overlay.EmbeddedOverlay;
import overlay.CustomOverlayContent;

/*
    Demonstrates HaxeFolioApp.embed: two embedded frames in the page, the second under a per-embed
    appearance (Outlined emphasis plus a style class), and buttons to change the first one's frame
    height and to detach it. onClose detaches both - the teardown hook of each logs to the console.
*/
class EmbedDemoPage extends PageBase
{
    private var plain:EmbeddedOverlay;
    private var themed:EmbeddedOverlay;

    public function new()
    {
        super();
    }

    private override function init():Void
    {
        this.layout = new VerticalLayout();
        this.verticalSpacing = 6;

        setTitle("Embed Demo");

        addComponent(sectionLabel("Embedded, frameHeight 300"));

        var plainHost:Box = new Box();
        plainHost.percentWidth = 100;
        addComponent(plainHost);
        plain = HaxeFolioApp.embed("embed-plain", () -> CustomOverlayContent.buildEmbedded("plain"), plainHost, 300);

        var resizeRow:HBox = new HBox();
        resizeRow.addComponent(button("Frame 300", () -> plain.frameHeight = 300));
        resizeRow.addComponent(button("Frame 180", () -> plain.frameHeight = 180));
        resizeRow.addComponent(button("Frame 60 (fixed exceeds frame)", () -> plain.frameHeight = 60));
        resizeRow.addComponent(button("Detach", () -> plain.detach()));
        addComponent(resizeRow);

        addComponent(sectionLabel("Embedded with appearance {emphasis: Outlined, styleClass: sample-overlay-variant}, frameHeight 260"));

        var themedHost:Box = new Box();
        themedHost.percentWidth = 100;
        addComponent(themedHost);
        themed = HaxeFolioApp.embed("embed-themed", () -> CustomOverlayContent.buildEmbedded("themed"), themedHost, 260, {emphasis: Outlined, styleClass: "sample-overlay-variant"});
    }

    private override function onClose():Void
    {
        plain.detach();
        themed.detach();
    }

    private static function sectionLabel(text:String):Label
    {
        var result:Label = new Label();
        result.text = text;
        result.addClass("haxefolio-label");
        return result;
    }

    private static function button(text:String, onPress:Void->Void):Button
    {
        var result:Button = new Button();
        result.text = text;
        result.addClass("haxefolio-button");
        result.onClick = _ -> onPress();
        return result;
    }
}
