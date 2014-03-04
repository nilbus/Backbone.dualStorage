{Backbone, localStorage} = window

describe 'monkey patching', ->
  it 'aliases Backbone.sync to backboneSync', ->
    expect(window.backboneSync).toBeDefined()
    expect(window.backboneSync.identity).toEqual('sync')

describe 'offline localStorage sync', ->
  {collection} = {}
  {model} = {}
  model = Backbone.Model.extend
    idAttribute: '_id'
  beforeEach ->
    localStorage.clear()
    localStorage.setItem 'cats', '1,2,3,a,deadbeef-c03d-f00d-aced-dec0ded4b1ff'
    localStorage.setItem 'cats_dirty', '2,a,deadbeef-c03d-f00d-aced-dec0ded4b1ff'
    localStorage.setItem 'cats_destroyed', '3'
    localStorage.setItem 'cats1', '{"_id": "1", "color": "translucent"}'
    localStorage.setItem 'cats2', '{"_id": "2", "color": "auburn"}'
    localStorage.setItem 'cats3', '{"_id": "3", "color": "burgundy"}'
    localStorage.setItem 'catsa', '{"_id": "a", "color": "scarlet"}'
    localStorage.setItem 'catsnew', '{"_id": "deadbeef-c03d-f00d-aced-dec0ded4b1ff", "color": "pearl"}'
    Collection = Backbone.Collection.extend
      model: model
      url: 'cats'
    collection = new Collection [
      {_id: 1, color: 'translucent'},
      {_id: 2, color: 'auburn'},
      {_id: 3, color: 'burgundy'},
      {_id: 'a', color: 'scarlet'}
      {_id: 'deadbeef-c03d-f00d-aced-dec0ded4b1ff', color: 'pearl'}
    ]

  describe 'syncDirtyAndDestroyed', ->
    it 'calls syncDirty and syncDestroyed', ->
      syncDirty = spyOn Backbone.Collection.prototype, 'syncDirty'
      syncDestroyed = spyOn Backbone.Collection.prototype, 'syncDestroyed'
      collection.syncDirtyAndDestroyed()
      expect(syncDirty).toHaveBeenCalled()
      expect(syncDestroyed).toHaveBeenCalled()

  describe 'syncDirty', ->
    it 'finds and saves all dirty models', ->
      saveInteger = spyOn(collection.get(2), 'save').andCallThrough()
      saveString = spyOn(collection.get('a'), 'save').andCallThrough()
      collection.syncDirty()
      expect(saveInteger).toHaveBeenCalled()
      expect(saveString).toHaveBeenCalled()
      expect(localStorage.getItem 'cats_dirty').toBeFalsy()

    it 'works when there are no dirty records', ->
      localStorage.removeItem 'cats_dirty'
      collection.syncDirty()

  describe 'syncDestroyed', ->
    it 'finds all models marked as destroyed and destroys them', ->
      destroy = spyOn collection.get(3), 'destroy'
      collection.syncDestroyed()
      expect(localStorage.getItem 'cats_destroyed').toBeFalsy()

    it 'works when there are no destroyed records', ->
      localStorage.setItem 'cats_destroyed', ''
      collection.syncDestroyed()

  describe 'dirtyModels', ->
    it 'returns the model instances that are dirty', ->
      expect(collection.dirtyModels().map((model) -> model.id)).toEqual [2, 'a', 'deadbeef-c03d-f00d-aced-dec0ded4b1ff']

  describe 'destoyedModelsIds', ->
    it 'returns the ids of models that have been destroyed locally but not synced', ->
      expect(collection.destroyedModelIds()).toEqual ['3']
