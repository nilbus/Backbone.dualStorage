{StickyStorageAdapter} = window.Backbone.storageAdapters

describe 'StickyStorageAdapter', ->
  describe 'creation', ->
    it 'takes a name in its constructor', ->
      # This should actually test that the created storage (IndexedDB, WebSQL, etc) uses this name.
      # But we trust Sticky to do its job :)
      storage = new StickyStorageAdapter 'SuperSizedStorage'
      expect(storage.name).toBe 'SuperSizedStorage'

    it 'initializes', ->
      storage = new StickyStorageAdapter
      storage.initialize().done ->
        expect(storage.store instanceof StickyStore).toBe true

  describe 'methods', ->
    it 'sets and gets a record', ->
      storage = new StickyStorageAdapter
      storage.initialize().done ->
        storage.setItem('key', {foo: 'bar'}).done ->
          storage.getItem('key').done (item) ->
            expect(item).toEqual foo: 'bar'

    it 'deletes a record', ->
      storage = new StickyStorageAdapter
      storage.initialize().done ->
        storage.setItem('key', {foo: 'bar'}).done ->
          storage.removeItem('key').done ->
            storage.getItem('key').done (item) ->
              expect(item).toBeNull()
