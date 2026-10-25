package haxefolio;

import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import js.Browser;
import morestd.Detachable;
import morestd.RefreshableTimer;

/*
    Reacts to viewport resizes: debounces them, then applies the layout thresholds (menuCollapseWidth,
    menuRailHeight) and notifies the active page with the page container's current pixel dimensions.

    Deliberately bypasses haxeui's own Screen/UIEvent.RESIZE machinery, which bottoms out in a
    plain `window` "resize" listener (see ScreenImpl.addResizeListener) - that listener isn't
    reliably fired by every viewport change a browser's device-emulation tools make (confirmed with
    Chrome's Device Toolbar), which leaves Screen.instance.width stuck at whatever it was cached as
    before, indefinitely. A native ResizeObserver instead reports an element's live, current size
    regardless of what caused it to change.

    The observed element is document.body, the viewport itself: the thresholds are properties of
    the viewport, not of any one component laid out in it.
*/
class ResponsivityController
{
    /** The current layout state, see `MenuLayout` **/
    public static var menuLayout(default, null):MenuLayout = Expanded;

    /** Carried by every root component while the layout is `Collapsed` or `Rail` **/
    public static inline final COMPACT_CLASS:String = "haxefolio-compact";
    /** Carried by every root component while the layout is exactly `Collapsed` (not `Rail`) **/
    public static inline final COLLAPSED_CLASS:String = "haxefolio-collapsed";
    /** Carried by every root component while the layout is `Expanded` **/
    public static inline final EXPANDED_CLASS:String = "haxefolio-expanded";
    /** Carried by every root component, along with `COMPACT_CLASS`, while the layout is `Rail` **/
    public static inline final RAIL_CLASS:String = "haxefolio-rail";
    /** Every root component carries, per tier scale, this prefix followed by `<scale>-<tier>` for the scale's current tier **/
    public static inline final TIER_CLASS_PREFIX:String = "haxefolio-tier-";

    // per scale: its tiers ascending by minWidth, the one in effect, and who follows it
    private static var tierScales:Null<Map<String, Array<WidthTier>>> = null;
    private static var currentTiers:Map<String, String> = [];
    private static var tierChangeListeners:Map<String, Array<String->Void>> = [];

    private static var menuLayoutChangeListeners:Array<MenuLayout->Void> = [];

    private static var pageContainer:Component;
    private static var menuCollapseWidth:Int;
    private static var menuRailHeight:Int;
    private static var onDebouncedResize:Float->Float->Void;
    private static var debounceTimer:RefreshableTimer;
    private static var latestWidth:Float;
    private static var latestHeight:Float;
    private static var hasAppliedInitialState:Bool;

    public static function init(pageContainer:Component, menuCollapseWidth:Int, menuRailHeight:Int, widthTiers:Array<WidthTier>, debounceMs:Int, onDebouncedResize:Float->Float->Void):Void
    {
        tierScales = buildTierScales(widthTiers);
        for (scale => tiers in tierScales)
        {
            currentTiers.set(scale, tiers[0].name); // until the first measurement
            tierChangeListeners.set(scale, []);
        }
        ResponsivityController.pageContainer = pageContainer;
        ResponsivityController.menuCollapseWidth = menuCollapseWidth;
        ResponsivityController.menuRailHeight = menuRailHeight;
        ResponsivityController.onDebouncedResize = onDebouncedResize;
        ResponsivityController.hasAppliedInitialState = false;

        debounceTimer = new RefreshableTimer(debounceMs, applyResize);

        /*
            No synchronous initial read here - haxeui defers actual layout validation, so even a
            direct DOM measurement can still read as 0 immediately after addComponent. ResizeObserver
            is guaranteed to fire once, promptly, as soon as observe() is called, reporting the
            element's real current size - onElementResized treats that first callback as the
            (undebounced) initial application, and every later one as an actual resize.
        */
        var observer:Dynamic = js.Syntax.code("new ResizeObserver({0})", onElementResized);
        observer.observe(Browser.document.body);
    }

    private static function onElementResized(entries:Array<Dynamic>):Void
    {
        var contentRect:Dynamic = entries[0].contentRect;
        latestWidth = contentRect.width;
        latestHeight = contentRect.height;

        if (!hasAppliedInitialState)
        {
            hasAppliedInitialState = true;
            applyMenuLayout();
            applyTiers();

            for (root in Screen.instance.rootComponents)
                markRoot(root);
        }
        else
            debounceTimer.start();
    }

    private static function applyResize():Void
    {
        debounceTimer.stop();

        applyMenuLayout();
        applyTiers();
        onDebouncedResize(pageContainer.element.offsetWidth, pageContainer.element.offsetHeight);
    }

    private static function applyMenuLayout():Void
    {
        var newLayout:MenuLayout = if (latestHeight < menuRailHeight && latestWidth > latestHeight)
            Rail;
        else if (latestWidth < menuCollapseWidth)
            Collapsed;
        else
            Expanded;

        if (newLayout == menuLayout)
            return;

        menuLayout = newLayout;

        for (root in Screen.instance.rootComponents)
            markRoot(root);

        for (listener in menuLayoutChangeListeners.copy())
            listener(menuLayout);
    }

    private static function applyTiers():Void
    {
        var changedScales:Array<String> = [];
        for (scale => tiers in tierScales)
        {
            var newTier:String = tiers[0].name;
            for (tier in tiers)
                if (latestWidth >= tier.minWidth && (tier.fits == null || tier.fits(latestWidth, latestHeight)))
                    newTier = tier.name;

            if (newTier != currentTiers.get(scale))
            {
                currentTiers.set(scale, newTier);
                changedScales.push(scale);
            }
        }
        if (changedScales.length == 0)
            return;

        for (root in Screen.instance.rootComponents)
            markRoot(root);

        for (scale in changedScales)
            for (listener in tierChangeListeners.get(scale).copy())
                listener(currentTiers.get(scale));
    }

    private static function buildTierScales(widthTiers:Array<WidthTier>):Map<String, Array<WidthTier>>
    {
        var result:Map<String, Array<WidthTier>> = [];
        for (tier in widthTiers)
        {
            if (tier.minWidth < 0)
                throw 'ResponsivityController: width tier "${tier.scale}/${tier.name}" must not start below 0.';
            if (tier.minWidth == 0 && tier.fits != null)
                throw 'ResponsivityController: width tier "${tier.scale}/${tier.name}" starts at 0, so it is the fallback and must not have `fits`.';

            var tiers:Array<WidthTier> = result.get(tier.scale) ?? [];
            for (existing in tiers)
            {
                if (existing.name == tier.name)
                    throw 'ResponsivityController: width tier name "${tier.name}" is used twice in scale "${tier.scale}".';
                if (existing.minWidth == tier.minWidth)
                    throw 'ResponsivityController: width tiers "${existing.name}" and "${tier.name}" of scale "${tier.scale}" start at the same width.';
            }
            tiers.push(tier);
            result.set(tier.scale, tiers);
        }

        for (scale => tiers in result)
        {
            tiers.sort((a, b) -> a.minWidth - b.minWidth);
            if (tiers[0].minWidth != 0)
                throw 'ResponsivityController: tier scale "${scale}" must have a tier starting at 0.';
        }
        return result;
    }

    /*
        Gives `root`, a Screen root component, the current layout's classes and each scale's tier class. HaxeUI
        re-matches a component's selectors only when that component's own style is invalidated, so on
        a change the whole subtree is invalidated, for `.haxefolio-compact .foo` rules to apply. HaxeFolio calls
        this for each root it adds to Screen.
    */
    @:allow(haxefolio)
    private static function markRoot(root:Component):Void
    {
        var layoutClasses:Map<String, Bool> = [
            EXPANDED_CLASS => menuLayout == Expanded,
            COMPACT_CLASS => menuLayout != Expanded,
            COLLAPSED_CLASS => menuLayout == Collapsed,
            RAIL_CLASS => menuLayout == Rail
        ];
        var upToDate:Bool = true;
        for (layoutClass => carried in layoutClasses)
            upToDate = upToDate && root.hasClass(layoutClass) == carried;
        for (scale => tier in currentTiers)
            upToDate = upToDate && root.hasClass(tierClass(scale, tier));
        if (upToDate)
            return;

        for (layoutClass => carried in layoutClasses)
            if (carried)
                root.addClass(layoutClass, false);
            else
                root.removeClass(layoutClass, false);
        if (tierScales != null) // roots marked before init carry no tier classes yet
            for (scale => tiers in tierScales)
                for (tier in tiers)
                    if (tier.name != currentTiers.get(scale))
                        root.removeClass(tierClass(scale, tier.name), false);
        for (scale => tier in currentTiers)
            root.addClass(tierClass(scale, tier), false);
        root.invalidateComponentStyle();
        invalidateDescendantStyles(root);
    }

    private static function tierClass(scale:String, tier:String):String
    {
        return TIER_CLASS_PREFIX + scale + "-" + tier;
    }

    private static function invalidateDescendantStyles(component:Component):Void
    {
        for (child in component.childComponents)
        {
            child.invalidateComponentStyle();
            invalidateDescendantStyles(child);
        }
    }

    /**
        The framework's only layout subscription: applies `value` for the current state
        immediately, then re-applies it whenever `menuLayout` changes in a way that changes the
        resolved value (not on every debounced resize) - so a component built after the initial
        layout still starts in sync rather than assuming the collapsed default. Anything whose
        layout depends on the layout state beyond what the menu itself already reacts to takes a
        `ByMenuLayout` and passes it through here.

        Detach the returned handle once the subscriber is disposed. For a constant `ByMenuLayout`,
        `apply` runs once and nothing is subscribed, so the handle is a harmless no-op.
    **/
    public static function bind<T>(value:ByMenuLayout<T>, apply:T->Void):Detachable
    {
        if (value.isConstant)
        {
            apply(value.resolve(menuLayout));
            return new Detachable(() -> {});
        }

        var applied:Null<T> = null;
        var hasApplied:Bool = false;

        return onMenuLayoutChange(layout -> {
            var resolved:T = value.resolve(layout);
            if (hasApplied && resolved == applied)
                return;

            hasApplied = true;
            applied = resolved;
            apply(resolved);
        });
    }

    /**
        The tier of `scale` currently in effect: the one with the greatest `minWidth` the viewport
        reaches whose `fits`, if any, holds. Throws for a scale not declared in `HaxeFolioConfig.widthTiers`.
    **/
    public static function currentTier(scale:String):String
    {
        var tier:Null<String> = currentTiers.get(scale);
        if (tier == null)
            throw 'ResponsivityController: no tier scale "${scale}".';
        return tier;
    }

    /**
        Calls `apply` with the current tier of `scale` immediately, then whenever it changes - after
        the root classes are updated, and after the `bind` subscribers if the layout state changed
        too. Detach the returned handle once the subscriber is disposed.
    **/
    public static function bindTier(scale:String, apply:String->Void):Detachable
    {
        var tier:String = currentTier(scale);
        var listeners:Array<String->Void> = tierChangeListeners.get(scale);
        listeners.push(apply);
        apply(tier);

        return new Detachable(() -> listeners.remove(apply), false);
    }

    // notifies `listener` whenever `menuLayout` changes, immediately with the current value first
    @:allow(haxefolio)
    private static function onMenuLayoutChange(listener:MenuLayout->Void):Detachable
    {
        menuLayoutChangeListeners.push(listener);
        listener(menuLayout);

        return new Detachable(() -> menuLayoutChangeListeners.remove(listener), false);
    }
}
