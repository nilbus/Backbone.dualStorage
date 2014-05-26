{Backbone} = window

describe 'monkey patching', ->
  it 'aliases Backbone.sync to backboneSync', ->
    expect(window.backboneSync).toBeDefined()
    expect(window.backboneSync.identity).toEqual('sync')

describe 'offline storage sync', ->
  {collection} = {}

  beforeEach ->
    console.log 'beforeEach'
    done = false

    collection = new Backbone.Collection [
      {id: 2, color: 'auburn'},
      {id: 3, color: 'burgundy'},
      {id: 'a', color: 'scarlet'}
      {id: 'deadbeef-c03d-f00d-aced-dec0ded4b1ff', color: 'pearl'}
    ]
    collection.url = -> 'cats'

    runs ->
      console.log 'runs'
      Backbone.storageAdapter = new Backbone.storageAdapters.StickyStorageAdapter
      Backbone.storageAdapter.initialize().done ->
        console.log 'initialized'
        Backbone.storageAdapter.clear().done ->
          console.log 'cleared'
          items =
            cats: '2,3,a,deadbeef-c03d-f00d-aced-dec0ded4b1ff'
            cats_dirty: '2,a,deadbeef-c03d-f00d-aced-dec0ded4b1ff'
            cats_destroyed: '3'
            cats2: '{"id": "2", "color": "auburn"}'
            cats3: '{"id": "3", "color": "burgundy"}'
            catsa: '{"id": "a", "color": "scarlet"}'
            catsnew: '{"id": "deadbeef-c03d-f00d-aced-dec0ded4b1ff", "color": "pearl"}'
          $.when((Backbone.storageAdapter.setItem(key, value) for key, value of items)...).done ->
            console.log 'done'
            done = true

    waitsFor -> done

  describe 'syncDirtyAndDestroyed', ->
    it 'calls syncDirty and syncDestroyed', ->
      syncDirty = spyOn(Backbone.Collection.prototype, 'syncDirty').andCallThrough()
      syncDestroyed = spyOn(Backbone.Collection.prototype, 'syncDestroyed').andCallThrough()
      collection.syncDirtyAndDestroyed().then ->
        expect(syncDirty).toHaveBeenCalled()
        expect(syncDestroyed).toHaveBeenCalled()

  describe 'syncDirty', ->
    it 'finds and saves all dirty models', ->
      saveInteger = spyOn(collection.get(2), 'save').andCallThrough()
      saveString = spyOn(collection.get('a'), 'save').andCallThrough()
      collection.syncDirty().then ->
        expect(saveInteger).toHaveBeenCalled()
        expect(saveString).toHaveBeenCalled()
        Backbone.storageAdapter.getItem('cats_dirty').then (item) ->
          expect(item).toBeFalsy()

    it 'works when there are no dirty records', ->
      Backbone.storageAdapter.removeItem('cats_dirty').then ->
        collection.syncDirty()

  describe 'syncDestroyed', ->
    it 'finds all models marked as destroyed and destroys them', ->
      destroy = spyOn collection.get(3), 'destroy'
      collection.syncDestroyed().then ->
        Backbone.storageAdapter.getItem('cats_destroyed').then (item) ->
          expect(item).toBeFalsy()

    it 'works when there are no destroyed records', ->
      Backbone.storageAdapter.setItem('cats_destroyed', '').then ->
        collection.syncDestroyed()
