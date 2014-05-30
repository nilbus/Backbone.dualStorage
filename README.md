Backbone dualStorage Adapter v1.3.1
===================================

A dualStorage adapter for Backbone. It's a drop-in replacement for Backbone.Sync() to handle saving to a localStorage database as a cache for the remote models.

Usage
-----

Include Backbone.dualStorage after having included Backbone.js:

    <script type="text/javascript" src="backbone.js"></script>
    <script type="text/javascript" src="backbone.dualstorage.js"></script>

Create your models and collections in the usual way.
Feel free to use Backbone as you usually would; this is a drop-in replacement.

Keep in mind that Backbone.dualStorage really loves your models. By default it will cache everything that passes through Backbone.sync. You can override this behaviour with the booleans ```remote``` or ```local``` on models and collections:

    SomeCollection = Backbone.Collection.extend({
        remote: true // never cached, dualStorage is bypassed entirely
        local: true  // always fetched and saved only locally, never saves on remote
        local: function() { return trueOrFalse; } // local and remote can also be dynamic
    });

You can also deactivate dualsync to some requests, when you want to sync with the server only later.

    SomeCollection.create({name: "someone"}, {remote: false});

Data synchronization
--------------------

When the client goes offline, dualStorage allows you to keep changing and destroying records. All changes will be sent when the client goes online again.

    // server online. Go!
    people.fetch();       // load cars models and save them into localstorage

    // server offline!
    people.create({name: "Turing"});   // you still can create new cars...
    people.models[0].save({age: 41});  // update existing ones...
    people.models[1].destroy();        // and destroy as well

    // collections track what is dirty and destroyed
    people.dirtyModels()               // => Array of dirty models
    people.destroyedModelIds()         // => Array of destroyed model ids

    // server online again!
    people.syncDirtyAndDestroyed();    // all changes are sent to the server and localStorage is updated

Keep in mind that if you try to fetch() a collection that has dirty data, only data currently in the localStorage will be loaded. collection.syncDirtyAndDestroyed() needs to be executed before trying to download new data from the server.

It is possible to tell whether the operation succeeded remotely or locally by examining `options.dirty` in the `success` callback:

	model.save({
		name: "Turing"
	}, {
		success: function(model, response, options) {
			if (options.dirty) {
				// saved locally
			} else {
				// saved remotely
			}
		}
	});

Offline state detection
-----------------------
dualStorage **always** treats an Ajax status code of `0` as an indication it is working offline. Additional status codes can be added by setting `offlineStatusCodes` to either an array:

    Backbone.DualStorage.offlineStatusCodes = [408];

or a function that accepts the `response` object and returns an array:

    Backbone.DualStorage.offlineStatusCodes = function(response) {
        var codes = [];

        if (...) {
            codes.push(response.status);
        }

        return codes;
    }


Data parsing
------------

Sometimes you may want to customize how data from the remote server is parsed before it's saved to localStorage.
Typically your model's `parse` method takes care of this.
Since dualStorage provides two layers of backend, we need a second parse method.
For example, if your remote API returns data in a way that the default `parse` method interprets the result as a single record,
use `parseBeforeLocalSave` to break up the data into an array of records like you would with [parse](http://backbonejs.org/#Model-parse).

* The model's `parse` method still parses data read from localStorage.
* The model's `parseBeforeLocalSave` method parses data read from the remote _before_ it is saved to localStorage on read.

Local data storage
------------------

dualStorage stores the local cache in localStorage.
Each collection's (or model's) `url` property is used as the storage namespace to separate different collections of data.
This can be overridden by defining a `storeName` property on your model or collection.
Defining storeName can be useful when your url is dynamic or when your models do not have the collection set but should be treated as part of that collection in the local cache.

Compiling
---------

Compile the coffeescript into javascript with `make`. This requires that node.js and coffee-script are installed.

    npm install -g coffee-script

    make

During development, use `make watch` to compile as you make changes.

Testing
-------

To run the test suite, clone the project and open **SpecRunner.html** in a browser.

Note that the tests run against **spec/backbone.dualstorage.js**, not the copy in the project root.
The spec version needs to be unwrapped to allow mocking components for testing.
This version is compiled automatically when running `make`.

dualStorage has been tested against Backbone versions 0.9.2 - 1.1.2.
Test with other versions by altering the version included in `SpecRunner.html`.

Authors
-------

Thanks to [Edward Anderson](https://github.com/nilbus) for the test suite and continued maintenance.
Thanks to [Lucian Mihaila](https://github.com/lucian1900) for creating Backbone.dualStorage.
Thanks to [Jerome Gravel-Niquet](https://github.com/jeromegn) for Backbone.localStorage.
