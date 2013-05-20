describe 'monkey patching', ->
  it 'aliases Backbone.sync to backboneSync', ->
    expect(window.backboneSync).toBeDefined()
    expect(window.backboneSync.identity).toEqual('sync')

describe 'offline localStorage sync', ->
  {collection} = {}
  beforeEach ->
    window.localStorage.clear()
    window.localStorage.setItem 'cats', '2,3'
    window.localStorage.setItem 'cats_dirty', '2'
    window.localStorage.setItem 'cats_destroyed', '3'
    window.localStorage.setItem 'cats3', '{"id": "2", "color": "auburn"}'
    window.localStorage.setItem 'cats3', '{"id": "3", "color": "burgundy"}'
    collection = new window.Backbone.Collection [{id: 2, color: 'auburn'}, {id: 3, color: 'burgundy'}]
    collection.url = -> 'cats'

  describe 'syncDirtyAndDestroyed', ->
    it 'calls syncDirty and syncDestroyed', ->
      syncDirty = spyOn window.Backbone.Collection.prototype, 'syncDirty'
      syncDestroyed = spyOn window.Backbone.Collection.prototype, 'syncDestroyed'
      collection.syncDirtyAndDestroyed()
      expect(syncDirty).toHaveBeenCalled()
      expect(syncDestroyed).toHaveBeenCalled()

  describe 'syncDirty', ->
    it 'finds and saves all dirty models', ->
      save = spyOn(collection.get(2), 'save').andCallThrough()
      collection.syncDirty()
      expect(save).toHaveBeenCalled()
      expect(window.localStorage.getItem 'cats_dirty').toBeFalsy()

  describe 'syncDestroyed', ->
    it 'finds all models marked as destroyed and destroys them', ->
      destroy = spyOn collection.get(3), 'destroy'
      collection.syncDestroyed()
      expect(window.localStorage.getItem 'cats_destroyed').toBeFalsy()

  describe 'with collection url as function', ->
    beforeEach ->
      window.localStorage.clear()
      window.localStorage.setItem 'cats', '2,3'
      window.localStorage.setItem 'cats_dirty', '2'
      window.localStorage.setItem 'cats_destroyed', '3'
      window.localStorage.setItem 'cats3', '{"id": "2", "color": "auburn"}'
      window.localStorage.setItem 'cats3', '{"id": "3", "color": "burgundy"}'
      collection = new window.Backbone.Collection [{id: 2, color: 'auburn'}, {id: 3, color: 'burgundy'}]
      collection.url = -> 'cats'

    describe 'syncDirty', ->
      it 'finds and saves all dirty models', ->
        save = spyOn(collection.get(2), 'save').andCallThrough()
        collection.syncDirty()
        expect(save).toHaveBeenCalled()
        expect(window.localStorage.getItem 'cats_dirty').toBeFalsy()

    describe 'syncDestroyed', ->
      it 'finds all models marked as destroyed and destroys them', ->
        destroy = spyOn collection.get(3), 'destroy'
        collection.syncDestroyed()
        expect(window.localStorage.getItem 'cats_destroyed').toBeFalsy()
    
