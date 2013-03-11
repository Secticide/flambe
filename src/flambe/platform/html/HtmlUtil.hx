//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.platform.html;

import js.Browser;

import flambe.display.Orientation;

class HtmlUtil
{
    public static var VENDOR_PREFIXES = [ "webkit", "moz", "ms", "o", "khtml" ];

    /**
     * Whether the annoying scrolling address bar in some iOS and Android browsers may be hidden.
     */
    public static var SHOULD_HIDE_MOBILE_BROWSER =
        Browser.window.top == Browser.window &&
        ~/Mobile(\/.*)? Safari/.match(Browser.window.navigator.userAgent);

    public static function callLater (func :Void -> Void, delay :Int = 0)
    {
        (untyped Browser.window).setTimeout(func, delay);
    }

    public static function hideMobileBrowser ()
    {
        Browser.window.scrollTo(1, 0);
    }

    // Load a prefixed vendor extension
    public static function loadExtension (
        name :String, ?obj :Dynamic) :{ prefix :String, field :String, value :Dynamic }
    {
        if (obj == null) {
            obj = Browser.window;
        }

        // Try to load it as is
        var extension = Reflect.field(obj, name);
        if (extension != null) {
            return {prefix: null, field: name, value: extension};
        }

        // Look through common vendor prefixes
        var capitalized = name.charAt(0).toUpperCase() + name.substr(1);
        for (prefix in VENDOR_PREFIXES) {
            var field = prefix + capitalized;
            var extension = Reflect.field(obj, field);
            if (extension != null) {
                return {prefix: prefix, field: field, value: extension};
            }
        }

        // Not found
        return {prefix: null, field: null, value: null};
    }

    public static function loadFirstExtension (
        names :Array<String>, ?obj :Dynamic) :{ prefix :String, field :String, value :Dynamic }
    {
        for (name in names) {
            var extension = loadExtension(name, obj);
            if (extension.field != null) {
                return extension;
            }
        }

        // Not found
        return {prefix: null, field: null, value: null};
    }

    // Loads a vendor extension and jams it into the supplied object
    public static function polyfill (name :String, ?obj :Dynamic) :Bool
    {
        if (obj == null) {
            obj = Browser.window;
        }

        var value = loadExtension(name, obj).value;
        if (value == null) {
            return false;
        }
        Reflect.setField(obj, name, value);
        return true;
    }

    public static function setVendorStyle (element :Dynamic, name :String, value :String)
    {
        var style = element.style;
        for (prefix in VENDOR_PREFIXES) {
            style.setProperty("-" + prefix + "-" + name, value);
        }
        style.setProperty(name, value);
    }

    public static function addVendorListener (dispatcher :Dynamic, type :String,
        listener :Dynamic -> Void, useCapture :Bool)
    {
        for (prefix in VENDOR_PREFIXES) {
            dispatcher.addEventListener(prefix + type, listener, useCapture);
        }
        dispatcher.addEventListener(type, listener, useCapture);
    }

    /**
     * Get a Flambe orientation from a window.orientation angle.
     */
    public static function orientation (angle :Int) :Orientation
    {
        switch (angle) {
            case -90, 90: return Landscape;
            default: return Portrait;
        }
    }

    /** Gets the current time in milliseconds since the Unix epoch. */
    inline public static function now () :Float
    {
        // Same thing as Date.now().getTime(), but avoids creating a Date object
        return (untyped Date).now();
    }

    public static function createEmptyCanvas (width :Int, height :Int) :Dynamic
    {
        var canvas :Dynamic = Browser.document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        return canvas;
    }

    public static function createCanvas (source :Dynamic) :Dynamic
    {
        var canvas = createEmptyCanvas(source.width, source.height);

        var ctx = canvas.getContext("2d");
        ctx.save();
        ctx.globalCompositeOperation = "copy";
        ctx.drawImage(source, 0, 0);
        ctx.restore();

        return canvas;
    }
}
