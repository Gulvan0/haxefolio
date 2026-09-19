package haxefolio.form.plumbing;

enum CommitResult
{
    Applied;
    Rejected(message:String);
}
