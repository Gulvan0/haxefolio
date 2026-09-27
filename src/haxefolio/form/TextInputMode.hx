package haxefolio.form;

/**
    What a TextInputField's input shows of its text.
**/
enum TextInputMode
{
    /**
        The text as typed.
    **/
    Plain;

    /**
        The text obscured.
    **/
    Password;

    /**
        The text obscured, with an eye toggle at the input's right edge that shows it and hides it
        again. The toggle replaces a "repeat password" field: the user checks what they typed
        instead of typing it twice.
    **/
    RevealablePassword;
}
