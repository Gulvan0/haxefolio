package haxefolio.form.plumbing;

/*
    How a ChoiceGrid selects: `Single` (at most one option; `selected == null` means none of the
    options matches, which is legitimate - see ChoiceGrid) or `Multi` (any subset of the options).
    An enum rather than a mode flag plus a pair of fields, because the two modes carry different
    callback shapes and would otherwise leave one set of fields unused.
*/
enum ChoiceGridSelection<T>
{
    /**
        `onSelect` is called with the clicked option's value.
    **/
    Single(selected:Null<T>, onSelect:T->Void);

    /**
        `onToggle` is called with the clicked option's value and its new membership in the selection.
    **/
    Multi(selected:Array<T>, onToggle:T->Bool->Void);
}
