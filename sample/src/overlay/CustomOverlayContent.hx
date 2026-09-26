package overlay;

import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.form.ChoiceRow;
import haxefolio.form.DurationField;
import haxefolio.form.IntField;
import haxefolio.form.SteppedValueField;
import haxefolio.form.ToggleButton;
import haxefolio.overlay.OverlayContent;
import haxefolio.structure.ActionBar;
import haxefolio.structure.ActionButton;
import haxefolio.structure.ErrorMarker;
import haxefolio.structure.Region;
import haxefolio.structure.TabPage;
import js.Browser;

/*
    Builder functions for the sample's own overlay content, each returning a fresh OverlayContent
    the way a real framework user's own content would be.
*/
class CustomOverlayContent
{
    public static function buildPlain():OverlayContent
    {
        return {
            regions: [
                Header("Plain overlay"),
                Scroll(body([label("A plain overlay: a Header and one Scroll region. The close control in the header and Esc both close it.")]))
            ]
        };
    }

    public static function buildDismissible(dismiss:Void->Void):OverlayContent
    {
        return {
            regions: [
                Header("Dismissible"),
                Scroll(body([label("The footer's button closes the overlay through the dismiss handle its factory received. Esc and the close control work too.")])),
                footer(dismiss)
            ]
        };
    }

    public static function buildDesktopVariant():OverlayContent
    {
        var columnA:Label = label("Expanded column A");
        columnA.percentWidth = 50;

        var columnB:Label = label("Expanded column B");
        columnB.percentWidth = 50;

        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.addComponent(columnA);
        row.addComponent(columnB);

        return {
            regions: [Header("Mobile variant"), Scroll(body([row]))]
        };
    }

    public static function buildMobileVariant():OverlayContent
    {
        return {
            regions: [Header("Mobile variant"), Scroll(body([label("Collapsed content - a genuinely different component tree from the expanded variant of this overlay.")]))]
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
            regions: [Header("Long content"), Scroll(body(lines)), footer(dismiss)],
            onDismissed: () -> Browser.console.log("[overlay-demo] content.onDismissed")
        };
    }

    /*
        Built under a per-overlay appearance (Outlined emphasis, plus a style class): the selected
        choice below must be drawn tinted-and-bordered rather than as a solid fill.
    */
    public static function buildAppearance(dismiss:Void->Void):OverlayContent
    {
        var row:ChoiceRow<String> = new ChoiceRow("Emphasis follows the overlay", [
            {value: "a", label: "First"},
            {value: "b", label: "Second"}
        ], "a", _ -> {});

        return {
            regions: [
                Header("Appearance override"),
                Scroll(body([label("This overlay overrides emphasis and carries a style class (tinted frame). Its primary button follows the emphasis too."), row])),
                footer(dismiss)
            ],
            onDismissed: row.dispose
        };
    }

    /*
        The Header/Actions regions in their less common shapes: a header without a close control
        (hideClose - this overlay's exit is the footer) and with a per-instance height, and an
        action bar mixing a fixed-width secondary button, a plain one and a primary one that a
        toggle enables/disables (a disabled primary must lose its emphasis).
    */
    public static function buildActions(dismiss:Void->Void):OverlayContent
    {
        var save:ActionButton = new ActionButton("Save & Close", dismiss, true, null, null, false);
        var cancel:ActionButton = new ActionButton("Cancel", dismiss);
        var reset:ActionButton = new ActionButton("Reset", () -> Browser.console.log("[overlay-demo] reset"), false, null, 25);

        var toggle:ToggleButton = new ToggleButton(on -> save.enabled = on, {on: "Saving allowed", off: "Saving blocked"});

        return {
            regions: [
                Header("Actions - no close control, 80px header", 80, true),
                Scroll(body([label("The header has no close control (hideClose), so the footer is the exit; Esc still works. Toggle below to enable the primary button."), toggle])),
                Actions(new ActionBar([reset, cancel, save]))
            ]
        };
    }

    /*
        A Navigate tab region, built to show the error markers (see ErrorMarker): one form cut into four
        pages sharing one footer, whose primary action is disabled for as long as any tab is marked.
        - "General" holds a toggle that drives the Extra tab's marker directly, the way a host would
          flag a problem it detected itself rather than through a field.
        - "Limits" holds two fields sharing one marker: the tab is marked while either is invalid
          (aggregating is the host's job). Only this page overflows and scrolls.
        - "Timing" opens already invalid and already marked, though its field shows only its neutral
          hint until touched - stepping it to a valid value clears the marker.
        - "Extra" carries an icon; its marker is the toggle's.
    */
    public static function buildNavigateTabs(dismiss:Void->Void):OverlayContent
    {
        var save:ActionButton = new ActionButton("Save & Close", dismiss, true);

        var limitsMarker:ErrorMarker = new ErrorMarker();
        var timingMarker:ErrorMarker = new ErrorMarker(true);
        var extraMarker:ErrorMarker = new ErrorMarker();

        var refreshSave:Void->Void = () -> save.enabled = !(limitsMarker.active || timingMarker.active || extraMarker.active);
        var limitsInvalid:Array<Bool> = [false, false];
        var updateLimits:Int->Bool->Void = (index, valid) -> {
            limitsInvalid[index] = !valid;
            limitsMarker.active = limitsInvalid[0] || limitsInvalid[1];
            refreshSave();
        };

        var limitA:SteppedValueField<Int> = IntField.create("Limit A", 10, _ -> {}, 1, 100, "1 to 100", "not a number", "out of range", true, valid -> updateLimits(0, valid));
        var limitB:SteppedValueField<Int> = IntField.create("Limit B", 20, _ -> {}, 1, 100, "1 to 100", "not a number", "out of range", true, valid -> updateLimits(1, valid));

        var limitsLines:Array<Component> = [for (i in 1...31) label('Limits line $i of 30 - this page scrolls on its own; the strip and footer stay put.')];
        limitsLines.unshift(limitB);
        limitsLines.unshift(limitA);
        limitsLines.unshift(label("Type e.g. 500 or abc into either field, then switch tabs: the Limits tab stays marked while at least one of them is invalid."));

        var timing:SteppedValueField<Int> = DurationField.create("Duration", 30, _ -> {}, 60, 3600, "1:00 to 60:00", "use m:ss", "out of range", true, valid -> {
            timingMarker.active = !valid;
            refreshSave();
        });

        var flagExtra:ToggleButton = new ToggleButton(on -> {
            extraMarker.active = on;
            refreshSave();
        }, {on: "Extra tab flagged invalid", off: "Flag the Extra tab as invalid"});

        var pages:Array<TabPage> = [
            {
                label: "General",
                content: body([
                    label("Toggle below to mark the Extra tab from code (no field involved). While any tab is marked the primary action is disabled."),
                    flagExtra
                ])
            },
            {
                label: "Limits",
                content: body(limitsLines),
                errorMarker: limitsMarker
            },
            {
                label: "Timing",
                content: body([
                    label("This tab opened already marked: 0:30 is below the 1:00 minimum, but the field shows only its neutral hint until touched. Press + to fix it."),
                    timing
                ]),
                errorMarker: timingMarker
            },
            {
                label: "Extra",
                icon: "haxefolio-sample/images/alt_close_icon.svg",
                content: body([label("A tab with an icon. Its marker follows the toggle on the General tab.")]),
                errorMarker: extraMarker
            }
        ];

        refreshSave();

        return {
            regions: [Header("Navigate tabs"), Tabs(Navigate, pages), Actions(new ActionBar([save]))]
        };
    }

    /*
        A Choose tab region: alternative forms with nothing shared. The frame title follows the tab
        (TabPage.title) and the host relabels its primary action per tab through onSelect.
    */
    public static function buildChooseTabs(dismiss:Void->Void):OverlayContent
    {
        var submit:ActionButton = new ActionButton("Sign in", dismiss, true);

        var pages:Array<TabPage> = [
            {
                label: "Sign in",
                title: "Sign in to the sample",
                content: body([label("Existing account: nothing on this tab is shared with the other one.")])
            },
            {
                label: "Sign up",
                title: "Create an account",
                content: body([label("New account."), new ChoiceRow("Plan", [{value: "free", label: "Free"}, {value: "pro", label: "Pro"}], "free", _ -> {})])
            }
        ];

        return {
            regions: [
                Header("Account"),
                Tabs(Choose, pages, null, index -> submit.text = index == 0 ? "Sign in" : "Sign up"),
                Actions(new ActionBar([submit]))
            ]
        };
    }

    /*
        Content for HaxeFolioApp.embed (see EmbedDemoPage): the same region model, with a footer whose
        action just logs since there is nothing to dismiss. The teardown hook logs to the console,
        which is how "detach() runs it exactly once" is checked.
    */
    public static function buildEmbedded(name:String):OverlayContent
    {
        var row:ChoiceRow<String> = new ChoiceRow("Emphasis (" + name + ")", [
            {value: "a", label: "First"},
            {value: "b", label: "Second"}
        ], "a", _ -> {});

        var lines:Array<Component> = [for (i in 1...21) label('Line $i of 20 - only this scrolling area scrolls; the footer stays put.')];
        lines.unshift(row);

        return {
            regions: [Header(name), Scroll(body(lines)), footer(() -> Browser.console.log('[embed-demo] $name footer action'))],
            onDismissed: () -> {
                row.dispose();
                Browser.console.log('[embed-demo] $name content.onDismissed');
            }
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
        return Actions(new ActionBar([new ActionButton("Save & Close", dismiss, true)]));
    }
}
