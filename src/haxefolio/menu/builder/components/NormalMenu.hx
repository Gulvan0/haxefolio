package haxefolio.menu.builder.components;

import haxe.ui.components.Label;
import haxe.ui.containers.menus.Menu;
import haxe.ui.core.Screen;
import haxefolio.menu.builder.MenuBuilderHelpers;
import js.Browser;
import js.html.CSSStyleDeclaration;
import js.html.CanvasRenderingContext2D;
import js.html.Element;

class NormalMenu extends Menu
{
    private static var measuringContext:Null<CanvasRenderingContext2D> = null;

    /*
        Called when the dropdown's width changed while it is open (see openPopup), for the menu bar
        to place it again.
    */
    public var onWidthRefitted:Null<Void->Void> = null;

    public function new(slug:String, items:Array<MenuItemDefinition>, ?defaultText:String)
    {
        super();

        this.id = 'haxefolio-normal-menu-$slug';
        this.text = MenuBuilderHelpers.resolveLabelText(defaultText, 'haxefolio.menubar.menu.$slug');
        this.addClass('haxefolio-normal-menu');
        this.verticalAlign = "center";

        for (item in items)
            this.addComponent(new NormalMenuItem(slug, item));
    }

    /*
        Runs when the menu bar puts the dropdown on screen, before it measures the dropdown to
        position it (see MenuBar's showMenu). HaxeUI renders a label's text only once the label is
        ready, a frame or so after it is first put on screen - so on the first open the labels
        can't be measured yet, and the width is fitted again on the next frame, telling the menu
        bar through `onWidthRefitted` if it changed, since the dropdown's placement depends on it.
    */
    public override function openPopup():Void
    {
        super.openPopup();
        fitWidthToLabels();

        Browser.window.requestAnimationFrame(_ -> {
            var isOpen:Bool = Screen.instance.rootComponents.indexOf(this) != -1;

            if (isOpen && fitWidthToLabels() && onWidthRefitted != null)
                onWidthRefitted();
        });
    }

    /*
        A dropdown is as wide as its widest label needs, never narrower than its stylesheet
        `min-width`: labels are single-line and never truncated. HaxeUI can't size it this way
        itself - an auto-width menu measures its items before their text is laid out, and collapses
        to the width of their padding - so the width is set here, on every open, since labels can
        change in between (a locale change, MenuFacade.updateMenuItemLabelText).

        A label's single-line width is measured from its text and computed font, so it doesn't
        matter whether the label is currently wrapped; a label whose text isn't rendered yet is
        skipped. Everything around the label - item and dropdown padding, icon, borders - is read
        off the current layout rather than repeated from the stylesheet. Returns whether the width
        changed.
    */
    private function fitWidthToLabels():Bool
    {
        this.syncComponentValidation();

        var neededWidth:Float = this.style?.minWidth ?? 0.0;

        for (child in this.childComponents)
        {
            if (child.hidden || !Std.isOfType(child, NormalMenuItem))
                continue;

            var label:Null<Label> = child.findComponent("menuitem-label", Label);
            if (label == null)
                continue;

            var textElement:Element = label.element.firstElementChild ?? label.element;
            if (textElement.textContent == "")
                continue;

            neededWidth = Math.max(neededWidth, this.width - label.width + measureSingleLine(textElement));
        }

        if (Math.abs(neededWidth - this.width) < 1)
            return false;

        this.width = Math.ceil(neededWidth);
        this.syncComponentValidation();
        return true;
    }

    private static function measureSingleLine(textElement:Element):Float
    {
        if (measuringContext == null)
            measuringContext = Browser.document.createCanvasElement().getContext2d();

        var computedStyle:CSSStyleDeclaration = Browser.window.getComputedStyle(textElement);
        measuringContext.font = '${computedStyle.fontStyle} ${computedStyle.fontWeight} ${computedStyle.fontSize} ${computedStyle.fontFamily}';

        // rounded up, as the browser rounds a text box's own width
        return Math.ceil(measuringContext.measureText(textElement.textContent).width);
    }
}
