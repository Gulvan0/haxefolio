package pages;

import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.layouts.VerticalLayout;
import haxefolio.PageBase;
import haxefolio.menu.MenuFacade;

/*
    Demonstrates every place a HaxeUI string (literal by default, {{key}} for locale, with or
    without params where supported) replaced what used to be an implicit locale key: page
    title/blink text (PageBase.setTitle/startBlink), and the site name/menu/item labels
    MenuFacade's update methods can change at runtime. See Main.hx for the equivalent demonstration
    at config time (siteName, NormalMenu/MenuItemDefinition's defaultText).
*/
class TextDemoPage extends PageBase
{
    public function new()
    {
        super();
    }

    private override function init():Void
    {
        this.layout = new VerticalLayout();
        this.verticalSpacing = 6;

        setTitle("Text Demo (literal)");

        addComponent(sectionLabel("Page title - PageBase.setTitle(text, ?param0..3)"));
        addComponent(button("Title: literal", () -> setTitle("Text Demo (literal)")));
        addComponent(button("Title: locale, no params", () -> setTitle("{{page.textdemo.title}}")));
        addComponent(button("Title: locale, with params", () -> setTitle("{{page.textdemo.title_with_param}}", "Ada")));

        addComponent(sectionLabel("Tab notification - PageBase.startBlink(text, ?param0..3)"));
        addComponent(button("Blink: literal", () -> startBlink("New message!")));
        addComponent(button("Blink: locale, no params", () -> startBlink("{{page.textdemo.notification}}")));
        addComponent(button("Blink: locale, with params", () -> startBlink("{{page.textdemo.notification_with_param}}", 3)));
        addComponent(button("Stop blink", stopBlink));

        addComponent(sectionLabel("Site name - MenuFacade.updateSiteNameLabelText(text)"));
        addComponent(button("Site name: literal", () -> MenuFacade.updateSiteNameLabelText("HaxeFolio Sample (updated)")));
        addComponent(button("Site name: locale, no params", () -> MenuFacade.updateSiteNameLabelText("{{haxefolio.sample.site_name_locale}}")));
        addComponent(button("Site name: locale, with params", () -> MenuFacade.updateSiteNameLabelText('{{haxefolio.sample.site_name_greeting, "Ada"}}')));

        addComponent(sectionLabel("Menu/item labels - MenuFacade.updateMenuLabelText/updateMenuItemLabelText"));
        addComponent(button("\"Navigation\" label: literal", () -> MenuFacade.updateMenuLabelText("navigation", "Nav (updated)")));
        addComponent(button("\"Navigation\" label: locale", () -> MenuFacade.updateMenuLabelText("navigation", "{{alt.menubar.menu.navigation}}")));
        addComponent(button("\"Home\" item label: literal", () -> MenuFacade.updateMenuItemLabelText("navigation", "home", "Home (updated)")));
        addComponent(button("\"Home\" item label: locale", () -> MenuFacade.updateMenuItemLabelText("navigation", "home", "{{alt.menubar.menu.navigation.item.home}}")));
    }

    private function sectionLabel(text:String):Label
    {
        var label:Label = new Label();
        label.text = text;
        return label;
    }

    private function button(text:String, onClick:Void->Void):Button
    {
        var button:Button = new Button();
        button.text = text;
        button.onClick = _ -> onClick();
        return button;
    }
}
