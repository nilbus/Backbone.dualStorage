describe 'localSync', ->
  for storageName, storageClass of Backbone.storageAdapters
    do (storageName, storageClass) ->

      _describe = if storageClass is StickyStorage then describe.skip else describe
      _describe "with #{storageName}", ->
        {storage, store, model} = {}

        beforeEach (done) ->
          storage = new storageClass
          store = new Backbone.Store 'Store', storage
          model = new Backbone.Model
            id: 1
            abc: 123
          storage.initialize().done ->
            store.initialize().done -> done()

        afterEach (done) ->
          store.clear().done ->
            storage.clear().done ->
              done()

        it 'works correctly when merge == false', (done) ->

          Backbone.