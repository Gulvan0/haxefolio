package haxefolio.form;

import haxefolio.form.plumbing.DurationFormat;

/*
    A SteppedValueField over a duration held as whole seconds within `minSeconds`..`maxSeconds`
    (inclusive), typed and shown as `m:ss` / `h:mm:ss` (see DurationFormat). The format is not
    inferred for the user - state it in the label or `hint`. The -/+ buttons step by 60 seconds,
    clamped to the bounds. Out-of-range input is marked with `outOfRangeMessage`, not clamped.

    A static factory, not a subclass, for the same reason as IntField.
*/
class DurationField
{
    private static inline final STEP_SECONDS:Int = 60;

    public static function create(
        label:String,
        seconds:Int,
        onChange:Int->Void,
        minSeconds:Int,
        maxSeconds:Int,
        hint:String,
        invalidFormatMessage:String,
        outOfRangeMessage:String,
        enabled:Bool = true,
        ?onValidityChange:Bool->Void
    ):SteppedValueField<Int>
    {
        return new SteppedValueField<Int>(
            label,
            seconds,
            onChange,
            DurationFormat.parse,
            DurationFormat.format,
            (current, direction) -> Std.int(Math.max(minSeconds, Math.min(maxSeconds, current + direction * STEP_SECONDS))),
            candidate -> {value: candidate, valid: candidate >= minSeconds && candidate <= maxSeconds, message: outOfRangeMessage, touched: false},
            hint,
            invalidFormatMessage,
            enabled,
            onValidityChange
        );
    }
}
