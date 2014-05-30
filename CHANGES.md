### 1.3.1 / 2014-15-30

* Make syncDestroyed compatible with backbone >= 1.1.1
* Fix #94: Call the error callback when offline if the collection has never been fetched (Dave Taylor)
* Fix #99: Restore compatibility with lodash; incompatible since 1.2.0 (Aleksandr Motsjonov)

### 1.3.0 / 2014-05-10

* Fix #104, #67: Instead of treating ajax errors as offline, use the error callback (Elad Efrat)
* Fix #106: Restore proper call to a model's parse method; broken since 1.0.2 (Eduardo Matos)
* Fix #105: Always set options.dirty in callbacks when offline (Elad Efrat)
* Fix #93: syncDirty works when models use a custom idAttribute (Ben Salinas)
* Fix #78: Do not clear local collection cache when a model is fetched
* Add `make watch` for continual coffeescript compilation during development
* `make` compiles sourcemaps between coffeescript and javascript
* Prevent id duplication in the internal list of model ids for a collection when a model is fetched

### 1.2.0 / 2014-01-31

* Add dirty/destroyed querying via `Collection.dirtyModels` and `Collection.destroyedModelIds`
* Allow the default url-based storeName to be overriden with a `storeName` property on the model or collection
* Use `model.urlRoot` as the storeName, when available, before `model.url`.
  This fixes the issue described in #80 where models with the same `urlRoot`
  that are intended to be part of the same collection end up in different stores
  when the collection attribute is not set on the model.

  **Existing apps that rely on this incorrect behavior may break.**

  If your app expects models with the same `urlRoot` and differing `url`s to
  be in different stores locally, use the following workaround in your model:

        storeName: function() { return this.url() }

* Ensure models in the dirty list exist before saving.
  This mitigates concurrency issues noted in #62 until #35 is resolved, which should fix this problem.
* Guard against JSON.parse(null) for Android browsers
* Remove all usages of Model.clone() to play along with plugins (backbone-relational) that do not work with clone.
* Fix where fetching models/collections would not merge but overwrite locally stored attributes.
* Use the model idAttribute when saving models that were created offline.
  In this scenario, an update request (for an object with a temp ID) would be sent on save instead of a create request.

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
