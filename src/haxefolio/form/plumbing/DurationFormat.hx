package haxefolio.form.plumbing;

/*
    Strict parse/format pair for a duration in whole seconds, as used by DurationField. The
    accepted shapes are exactly the ones `format` produces: `m:ss` (minutes unbounded, so `90:00`
    is valid) and `h:mm:ss` (minutes and seconds two digits, each below 60). Anything else -
    a bare number, `1:5`, `1:60`, a sign, stray characters - is unparseable rather than
    guessed at, since the format is stated to the user, never inferred.
*/
class DurationFormat
{
    private static final MINUTES_SECONDS:EReg = ~/^(\d+):([0-5]\d)$/;
    private static final HOURS_MINUTES_SECONDS:EReg = ~/^(\d+):([0-5]\d):([0-5]\d)$/;

    /**
        Returns the number of seconds `text` denotes, or `null` if it is not a `m:ss` or `h:mm:ss`
        duration. Surrounding whitespace is ignored.
    **/
    public static function parse(text:String):Null<Int>
    {
        var trimmed:String = StringTools.trim(text);

        if (HOURS_MINUTES_SECONDS.match(trimmed))
            return Std.parseInt(HOURS_MINUTES_SECONDS.matched(1)) * 3600 + Std.parseInt(HOURS_MINUTES_SECONDS.matched(2)) * 60 + Std.parseInt(HOURS_MINUTES_SECONDS.matched(3));

        if (MINUTES_SECONDS.match(trimmed))
            return Std.parseInt(MINUTES_SECONDS.matched(1)) * 60 + Std.parseInt(MINUTES_SECONDS.matched(2));

        return null;
    }

    /**
        Renders `seconds` (non-negative) as `m:ss` below an hour and `h:mm:ss` from an hour up;
        `parse(format(x)) == x` for every non-negative `x`.
    **/
    public static function format(seconds:Int):String
    {
        var hours:Int = Std.int(seconds / 3600);
        var minutes:Int = Std.int((seconds % 3600) / 60);
        var remainder:Int = seconds % 60;

        if (hours > 0)
            return '$hours:${twoDigits(minutes)}:${twoDigits(remainder)}';

        return '$minutes:${twoDigits(remainder)}';
    }

    private static function twoDigits(value:Int):String
    {
        return value < 10 ? '0$value' : '$value';
    }
}
