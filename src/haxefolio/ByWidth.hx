package haxefolio;

enum ByWidthValue<T>
{
    Constant(value:T);
    Varying(expanded:T, collapsed:T);
}

/**
    A value that may differ between the two states of the application-wide breakpoint
    (`ResponsivityController.isCollapsed`): either one value, used in both, or an
    `{expanded:T, collapsed:T}` pair. Both convert implicitly:

    ```
    var perRow:ByWidth<Int> = 4;
    var perRow:ByWidth<Int> = {expanded: 5, collapsed: 3};
    ```

    Anything that varies by breakpoint takes a `ByWidth` and hands it to
    `ResponsivityController.bind`, rather than subscribing to the breakpoint itself.
**/
abstract ByWidth<T>(ByWidthValue<T>)
{
    /**
        Whether the value is the same in both states, i.e. nothing needs to react to the breakpoint.
    **/
    public var isConstant(get, never):Bool;

    private function new(value:ByWidthValue<T>)
    {
        this = value;
    }

    @:from
    public static function fromPair<T>(pair:{expanded:T, collapsed:T}):ByWidth<T>
    {
        return new ByWidth(Varying(pair.expanded, pair.collapsed));
    }

    @:from
    public static function fromValue<T>(value:T):ByWidth<T>
    {
        return new ByWidth(Constant(value));
    }

    /**
        The value for the given breakpoint state.
    **/
    public function resolve(collapsed:Bool):T
    {
        return switch this {
            case Constant(value): value;
            case Varying(expandedValue, collapsedValue): collapsed ? collapsedValue : expandedValue;
        }
    }

    private function get_isConstant():Bool
    {
        return switch this {
            case Constant(_): true;
            case Varying(_, _): false;
        }
    }
}
