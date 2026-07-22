package haxefolio;

typedef PageDefinition = {
    /**
        A URL page path template, checked top-to-bottom against the other registered definitions
        (the first match wins). Parameters are denoted by their names enclosed in curly braces,
        e.g. `"user/{login}"`, and are always parsed as strings.
    **/
    path:String,

    /**
        Builds the page from its parsed path parameters (an empty map if `path` has none). Called
        by the framework on every navigation to this page - never called directly by user code.
        If it throws, the website user is redirected to the default page.
    **/
    factory:Map<String, String>->PageBase,

    /**
        Marks this as the default page - the one opened when a URL doesn't resolve to any
        registered page, or when the site name is clicked. Exactly one page must set this to
        `true`, and its `path` must not contain parameters.
    **/
    ?isDefault:Bool
}
