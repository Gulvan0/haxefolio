package haxefolio.form;

/*
    A SteppedValueField over a whole number within `min`..`max` (inclusive): typed text must be a
    decimal integer (optional leading `-`, nothing else), and the -/+ buttons step by 1, clamped
    to the bounds. Out-of-range input is marked with `outOfRangeMessage`, not clamped.

    A static factory, not a subclass: HaxeUI's component macro rejects a subclass whose
    constructor repeats the parameter names of its component superclass's constructor.
*/
class IntField
{
    private static final INTEGER:EReg = ~/^-?\d+$/;

    public static function create(
        label:String,
        value:Int,
        onChange:Int->Void,
        min:Int,
        max:Int,
        hint:String,
        invalidFormatMessage:String,
        outOfRangeMessage:String,
        enabled:Bool = true,
        ?onValidityChange:Bool->Void
    ):SteppedValueField<Int>
    {
        return new SteppedValueField<Int>(
            label,
            value,
            onChange,
            parseInteger,
            Std.string,
            (current, direction) -> Std.int(Math.max(min, Math.min(max, current + direction))),
            candidate -> {value: candidate, valid: candidate >= min && candidate <= max, message: outOfRangeMessage, touched: false},
            hint,
            invalidFormatMessage,
            enabled,
            onValidityChange
        );
    }

    private static function parseInteger(text:String):Null<Int>
    {
        var trimmed:String = StringTools.trim(text);
        return INTEGER.match(trimmed) ? Std.parseInt(trimmed) : null;
    }
}
