package haxefolio.browser;

import js.Browser;
import js.html.AnchorElement;
import js.html.Blob;
import js.html.URL;

class FileDownload
{
    /** Hands `blob` to the browser as a download named `fileName` **/
    public static function save(blob:Blob, fileName:String):Void
    {
        var url:String = URL.createObjectURL(blob);

        var anchor:AnchorElement = Browser.document.createAnchorElement();
        anchor.href = url;
        anchor.download = fileName;
        anchor.style.display = "none";
        Browser.document.body.appendChild(anchor);
        anchor.click();
        anchor.remove();

        // revoked later: some browsers start reading the blob only after click() returns
        Browser.window.setTimeout(() -> URL.revokeObjectURL(url), 60000);
    }
}
