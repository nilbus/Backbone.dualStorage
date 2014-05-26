StickyStorage = Backbone.storageAdapters.StickyStorageAdapter

describe 'StorageAdapters', ->
  for storageName, storageClass of Backbone.storageAdapters
    do (storageName, storageClass) ->
      _describe = if storageClass is StickyStorage then describe.skip else describe
      _describe storageName, ->

        it 'takes a name in its constructor and initializes', (done) ->
          storage = new storageClass 'SuperSizedStorage'
          storage.initialize().done ->
            expect(storage.name).to.equal 'SuperSizedStorage'
            expect(storage.store).to.exist
            storage.clear().done ->
              done()

        _describe 'methods', ->
          {storage} = {}

          beforeEach (done) ->
            storage = new storageClass
            storage.initialize().done ->
              done()

          afterEach (done) ->
            storage.clear().done ->
              done()

          it 'sets and gets a record', (done) ->
            storage.set('item', foo: 'bar').done ->
              storage.get('item').done (item) ->
                expect(item).to.eql foo: 'bar'
                done()

          it 'deletes a record', (done) ->
            storage.set('item', foo: 'bar').done ->
              storage.remove('item').done ->
                storage.get('item').done (item) ->
                  expect(item).to.not.ok
                  done()

          it 'clears all records', (done) ->
            storage.set('item1', 1).done ->
              storage.set('item2', 2).done ->
                storage.clear().done ->
                  storage.get('item1').done (item1) ->
                    expect(item1).to.not.ok
                    storage.get('item2').done (item2) ->
                      expect(item2).to.not.ok
                      done()
