### 1.1.0 / 2013-11-10

* Add support for RequireJS / AMD

### 1.0.2 / 2013-11-10

* Fix support for models with a custom `idAttribute`
* Update locally cached attributes when the server response to a save updates attributes
* Add bower metadata
* Support non-numeric model ids
* Conform localSync to Backbone.sync protocol by returning attributes
* Fix support for models with `url` defined as a function

### 1.0.1 / 2013-03-27

* Add compatibility for Backbone 0.9.10
* Remove console.log calls for cleanup and IE support
* Add build Makefile for development
* Add test suite
* Add limited supoort for `fetch` add and merge options
* Support defining `parseBeforeLocalSave` on models for parsing server responses before passing them to localsync
* Support controlling behavior with `local`  and `remote` options

### 1.0.0 / 2013-01-27

* Forked Backbone.dualStorage from Backbone.localStorage
