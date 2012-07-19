This project is now dormant, as I no longer work on any project that needs it.

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

    
Keep in mind that Backbone.dualStorage really loves your models. By default it will cache everything that passes through Backbone.sync. You can override this behaviour with the booleans ```remote``` or ```local``` on models and collections:
    
    SomeCollection = Backbone.Collection.extend({
        local: true  // always fetched and saved only locally, never saves on remote
        remote: true // never cached, dualStorage is bypassed entirely
    });

You can also deactivate dualsync to some requests, when you want to sync with the server only later.

    SomeCollection.create({name: "someone"}, {remote: false});

Data synchronization
--------------------

When the client goes offline, dualStorage allows you to keep changing and destroying records. All changes will be send when the client goes online again.

    // server online. Go!
    People.fetch();       // load cars models and save them into localstorage
	
	// server offline!
	People.create({name: "Turing"});   // you still can create new cars...
	People.models[0].save({age: 41});  // update existing ones...
	People.models[1].destroy();        // and destroy as well
	
	// server online again!
	People.syncDirtyAndDestroyed();    // all changes are sent to the server and localStorage is updated

Keep in mind that if you try to fetch() a collection that has dirty data, only data currently in the localStorage will be loaded. collection.syncDirtyAndDestroyed() needs to be executed before trying to download new data from the server.

Data parsing
------------

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
