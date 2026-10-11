package haxefolio.form;

import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;

/*
    A caption row plus a fixed-size preview area for arbitrary host content (a rendered position,
    a colour swatch, a generated image). The area is always rendered and never resizes: the
    preview must not appear and disappear with a mode toggle - it shows the effective value in
    every mode, including the default one - so a host swaps `content` rather than adding/removing
    the pane.

    The caption is centred over the area. Its row is reserved (fixed height) whenever the pane is
    constructed with a caption or an icon, even if that caption is later set to an empty string, so
    a caption changing never moves the area. A pane constructed with neither has no caption row.

    The area clips (`clip: true`) rather than measuring around its content: content that does not
    fit the given size is a design error to fix, not a case to accommodate.
*/
class PreviewPane extends VBox
{
    private final area:Box;
    private final captionLabel:Null<Label>;
    private final captionImage:Null<Image>;
    private var currentContent:Component;

    /**
        The caption's text. Throws if the pane was constructed with neither a caption nor an icon
        (there is no reserved row to put it in).
    **/
    public var caption(get, set):String;

    /**
        The caption's icon. Throws if the pane was constructed without one (there is no slot for it
        in the reserved row).
    **/
    public var captionIcon(get, set):String;

    /**
        The hosted component. Assigning detaches the previous one (without disposing it, so the
        host may keep and reuse it) and puts the new one in its place.
    **/
    public var content(get, set):Component;

    public function new(previewWidth:Int, previewHeight:Int, content:Component, ?caption:String, ?captionIcon:String)
    {
        super();

        this.width = previewWidth;
        this.verticalSpacing = 0; // the caption row's own margin-bottom is the only caption-to-area gap
        this.addClass("haxefolio-preview-pane");

        if (caption != null || captionIcon != null)
        {
            var captionRow:HBox = new HBox();
            captionRow.horizontalAlign = "center";
            captionRow.horizontalSpacing = 6;
            captionRow.addClass("haxefolio-preview-pane-caption-row");
            this.addComponent(captionRow);

            if (captionIcon != null)
            {
                captionImage = new Image();
                captionImage.resource = captionIcon;
                captionImage.verticalAlign = "center";
                captionRow.addComponent(captionImage);
            }
            else
                captionImage = null;

            captionLabel = new Label();
            captionLabel.text = caption ?? "";
            captionLabel.verticalAlign = "center";
            captionLabel.addClass("haxefolio-preview-pane-caption");
            captionRow.addComponent(captionLabel);
        }
        else
        {
            captionLabel = null;
            captionImage = null;
        }

        area = new Box();
        area.width = previewWidth;
        area.height = previewHeight;
        area.addClass("haxefolio-preview-pane-area");
        this.addComponent(area);

        this.content = content;
    }

    private function get_caption():String
    {
        if (captionLabel == null)
            throw "PreviewPane: constructed without a caption or an icon, so it has no caption row";

        return captionLabel.text;
    }

    private function set_caption(value:String):String
    {
        if (captionLabel == null)
            throw "PreviewPane: constructed without a caption or an icon, so it has no caption row";

        captionLabel.text = value;
        return value;
    }

    private function get_captionIcon():String
    {
        if (captionImage == null)
            throw "PreviewPane: constructed without a caption icon";

        return captionImage.resource;
    }

    private function set_captionIcon(value:String):String
    {
        if (captionImage == null)
            throw "PreviewPane: constructed without a caption icon";

        captionImage.resource = value;
        return value;
    }

    private function get_content():Component
    {
        return currentContent;
    }

    private function set_content(value:Component):Component
    {
        if (currentContent != null)
            area.removeComponent(currentContent, false);

        currentContent = value;
        area.addComponent(value);
        return value;
    }
}
