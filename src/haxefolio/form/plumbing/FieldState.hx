package haxefolio.form.plumbing;

typedef FieldState<T> = {
    value:T,
    valid:Bool,
    message:Null<String>,
    touched:Bool
}
