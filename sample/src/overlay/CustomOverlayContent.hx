package overlay;

import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxefolio.overlay.OverlayContent;

/*
    Builder functions for the sample's own overlay content, mirroring the shape
    PreferenceWindowBuilder.build uses for the built-in preference window - each returns a fresh
    OverlayContent, built the same way a real framework user's own content would be.

    Each descriptive label gets an explicit `width` (rather than being left to its natural,
    unwrapped text width) so it wraps instead of forcing its container wider than it - this matters
    most for the mobile sidebar presentation, whose own width is pinned to 100% of the viewport
    regardless of what its content wants to be.
*/
class CustomOverlayContent
{
    private static inline var LABEL_WIDTH:Int = 260;

    public static function buildPlain():OverlayContent
    {
        var content:OverlayContent = new OverlayContent();
        var label:Label = new Label();
        label.width = LABEL_WIDTH;
        label.text = "A plain custom overlay - arbitrary framework-user content, sized and iconed entirely by CSS defaults.";
        content.addComponent(label);
        return content;
    }

    public static function buildDismissible(dismiss:Void->Void):OverlayContent
    {
        var content:OverlayContent = new OverlayContent();
        var label:Label = new Label();
        label.width = LABEL_WIDTH;
        label.text = "This overlay's own button closes it too, via the dismiss callback its factory received.";
        var saveButton:Button = new Button();
        saveButton.text = "Save & Close";
        saveButton.onClick = _ -> dismiss();
        content.addComponent(label);
        content.addComponent(saveButton);
        return content;
    }

    public static function buildNoCloseButton(dismiss:Void->Void):OverlayContent
    {
        var content:OverlayContent = new OverlayContent();
        var label:Label = new Label();
        label.width = LABEL_WIDTH;
        label.text = "Shown with showCloseButton: false - this button is the only way to close it.";
        var closeButton:Button = new Button();
        closeButton.text = "Close";
        closeButton.onClick = _ -> dismiss();
        content.addComponent(label);
        content.addComponent(closeButton);
        return content;
    }

    public static function buildDesktopVariant():OverlayContent
    {
        var content:OverlayContent = new OverlayContent();
        var row:HBox = new HBox();
        var left:Label = new Label();
        left.text = "Desktop column A";
        var right:Label = new Label();
        right.text = "Desktop column B";
        row.addComponent(left);
        row.addComponent(right);
        content.addComponent(row);
        return content;
    }

    public static function buildMobileVariant():OverlayContent
    {
        var content:OverlayContent = new OverlayContent();
        var label:Label = new Label();
        label.width = LABEL_WIDTH;
        label.text = "Mobile stacked content - genuinely different from the desktop variant of this overlay.";
        content.addComponent(label);
        return content;
    }

    public static function buildExplicitSize():OverlayContent
    {
        var content:OverlayContent = new OverlayContent();
        var label:Label = new Label();
        label.width = LABEL_WIDTH;
        label.text = "Shown with explicit width/height/closeButtonSize/insets, overriding CSS for this overlay only.";
        content.addComponent(label);
        return content;
    }
}
