package haxefolio.menu;

typedef MenuItemDefinition = {
    /**
        Identifies this item within its containing menu/group - used to build its locale key, e.g.
        `haxefolio.menubar.menu.<menu slug>.item.<slug>`.
    **/
    slug:String,

    /**
        What happens when this item is clicked - see `MenuAction`.
    **/
    action:MenuAction,

    /**
        Optional icon asset path shown next to the item's label.
    **/
    ?icon:String
}
