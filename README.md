Backbone dualStorage Adapter v1.0
=================================

A dualStorage adapter for Backbone. It's a drop-in replacement for Backbone.Sync() to handle saving to a localStorage database as a cache for the remote models.

Usage
-----

Include Backbone.dualStorage after having included Backbone.js:

    <script type="text/javascript" src="backbone.js"></script>
    <script type="text/javascript" src="backbone.dualstorage.js"></script>

Create your models and collections in the usual way. 
Feel free to use Backbone as you usually would, this is a drop-in replacement.

    
Keep in mind that Backbone.dualStorage really loves your models. By default it will cache everything that passes through Backbone.sync. You can override this behaviour with the booleans ```remote``` and ```local``` on models:
    
    SomeModel = Backbone.Collection.extend({
        local: true  // always fetched and saved locally
        remote: true // never cached, dualStorage is bypassed entirely
    });

### parseBeforeLocalSave

Sometimes you may want to customize how data from the remote server is parsed before it's saved to localStorage.
Typically your model's `parse` method takes care of this.
Since dualStorage provides two layers of backend, we need a second parse method.
For example, if your remote API returns data in a way that the default `parse` method interprets the result as a single record,
use `parseBeforeLocalSave` to break up the data into an array of records like you would with [parse](http://backbonejs.org/#Model-parse).

* The model's `parse` method still parses data read from localStorage.
* The model's `parseBeforeLocalSave` method parses data read from the remote _before_ it is saved to localStorage on read.

Credits
-------

Thanks to [Jerome Gravel-Niquet](https://github.com/jeromegn) for Backbone.dualStorage
