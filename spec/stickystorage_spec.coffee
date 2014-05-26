{StickyStorageAdapter} = window.Backbone.storageAdapters;

describe 'StickyStorageAdapter', ->
  beforeEach ->
    done = false
    runs ->
      storage = new StickyStorageAdapter
      storage.initialize().done ->
        storage.clear().done ->
          done = true
    waitsFor -> done

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
      {result} = {}
      runs ->
        storage = new StickyStorageAdapter
        storage.initialize().done ->
          storage.setItem('test', foo: 'bar').done ->
            storage.getItem('test').done (item) ->
              result = item
      waitsFor -> result?
      runs -> expect(result).toEqual foo: 'bar'

    it 'deletes a record', ->
      {result} = {}
      runs ->
        storage = new StickyStorageAdapter
        storage.initialize().done ->
          storage.setItem('test', foo: 'bar').done ->
            storage.removeItem('test').done ->
              storage.getItem('test').done (item) ->
                result = item
      waitsFor -> result?
      runs -> expect(result).toBeNull()
