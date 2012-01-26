# Backbone dualStorage Adapter v1.0

A dualStorage adapter for Backbone. It's a drop-in replacement for Backbone.Sync() to handle saving to a localStorage database as a cache for the remote models.

## Usage

Include Backbone.dualStorage after having included Backbone.js:

    <script type="text/javascript" src="backbone.js"></script>
    <script type="text/javascript" src="backbone.dualStorage.js"></script>

Create your collections in the usual way:

    window.SomeCollection = Backbone.Collection.extend({

      // ... everything is normal.

    });

Feel free to use Backbone as you usually would, this is a drop-in replacement.

## Credits

Thanks to [Mark Woodall](https://github.com/llad) for the QUnit tests.
Thanks to [Jerome Gravel-Niquet](https://github.com/jeromegn) for Backbone.dualStorage