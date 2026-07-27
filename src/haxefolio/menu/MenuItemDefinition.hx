package haxefolio.menu;

typedef MenuItemDefinition = {
    /**
        Identifies this item within its containing menu/group - also used to build its CSS id and,
        absent `defaultText`, its locale key, e.g. `haxefolio.menubar.menu.<menu slug>.item.<slug>`.
    **/
    slug:String,

    /**
        What happens when this item is clicked - see `MenuAction`.
    **/
    action:MenuAction,

    /**
        Optional icon asset path shown next to the item's label.
    **/
    ?icon:String,

    /**
        Used verbatim as the item's initial label, interpreted the same way any HaxeUI `.text`
        property is (a literal by default, or - enclosed in `{{}}` - a locale key); if omitted, the
        label defaults to the `<menu slug>.item.<slug>` locale key. Either way,
        `MenuFacade.updateMenuItemLabelText` can change it later.
    **/
    ?defaultText:String
}
