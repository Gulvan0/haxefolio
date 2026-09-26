package haxefolio.form.plumbing;

/**
    The captions of a `ToggleButton`, one per state, each interpreted like any HaxeUI `.text`
    property: a literal by default, or - wrapped in `{{}}` - a locale key.
**/
typedef ToggleLabels = {
    on:String,
    off:String
}
