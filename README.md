# Backbone dualStorage Adapter v1.0

A dualStorage adapter for Backbone. It's a drop-in replacement for Backbone.Sync() to handle saving to a localStorage database as a cache for the remote models.

## Usage

Include Backbone.dualStorage after having included Backbone.js:

    <script type="text/javascript" src="backbone.js"></script>
    <script type="text/javascript" src="backbone.dualstorage.js"></script>

Create your models and collections in the usual way. 
Feel free to use Backbone as you usually would, this is a drop-in replacement.

    
Keep in mind that Backbone.dualStorage really loves your models. By default it will cache everything that passes through Backbone.sync. You can override this behaviour with the booleans ```remote``` or ```local``` on models and collections:
    
    SomeCollection = Backbone.Collection.extend({
        local: true  // always fetched and saved only locally, never saves on remote
        remote: true // never cached, dualStorage is bypassed entirely
    });

You can also deactivate dualsync to some requests, when you want to sync with the server only later.

    SomeCollection.create({name: "someone"}, {remote: false});

## Credits

Thanks to [Mark Woodall](https://github.com/llad) for the QUnit tests.
Thanks to [Jerome Gravel-Niquet](https://github.com/jeromegn) for Backbone.dualStorage