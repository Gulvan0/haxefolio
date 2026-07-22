package haxefolio.preferences;

/*
    Tags a Preference with the control it should be rendered as in the preference window.
    Adding a new preference type (a new PreferenceRegistry factory method) means adding a case here
    and a corresponding branch in the window builder.
*/
enum PreferenceKind
{
    Toggle;
    Option;
}
