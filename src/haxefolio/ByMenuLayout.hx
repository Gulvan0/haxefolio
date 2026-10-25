package haxefolio;

enum ByMenuLayoutValue<T>
{
    Constant(value:T);
    Varying(expanded:T, collapsed:T, rail:T);
}

/**
    A value that may differ between the states of the application-wide layout
    (`ResponsivityController.menuLayout`): either one value, used in all of them, or an
    `{expanded:T, collapsed:T, ?rail:T}` structure, where an omitted `rail` takes the `collapsed`
    value. Both convert implicitly:

    ```
    var perRow:ByMenuLayout<Int> = 4;
    var perRow:ByMenuLayout<Int> = {expanded: 5, collapsed: 3};
    var perRow:ByMenuLayout<Int> = {expanded: 5, collapsed: 3, rail: 4};
    ```

    Anything that varies by layout takes a `ByMenuLayout` and hands it to
    `ResponsivityController.bind`, rather than subscribing to the layout itself.
**/
abstract ByMenuLayout<T>(ByMenuLayoutValue<T>)
{
    /**
        Whether the value is the same in every state, i.e. nothing needs to react to the layout.
    **/
    public var isConstant(get, never):Bool;

    private function new(value:ByMenuLayoutValue<T>)
    {
        this = value;
    }

    @:from
    public static function fromPair<T>(pair:{expanded:T, collapsed:T, ?rail:T}):ByMenuLayout<T>
    {
        return new ByMenuLayout(Varying(pair.expanded, pair.collapsed, pair.rail ?? pair.collapsed));
    }

    @:from
    public static function fromValue<T>(value:T):ByMenuLayout<T>
    {
        return new ByMenuLayout(Constant(value));
    }

    /**
        The value for the given layout state.
    **/
    public function resolve(layout:MenuLayout):T
    {
        return switch this {
            case Constant(value): value;
            case Varying(expandedValue, collapsedValue, railValue): switch layout {
                case Expanded: expandedValue;
                case Collapsed: collapsedValue;
                case Rail: railValue;
            }
        }
    }

    private function get_isConstant():Bool
    {
        return switch this {
            case Constant(_): true;
            case Varying(_, _, _): false;
        }
    }
}
