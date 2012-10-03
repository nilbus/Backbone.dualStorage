window = require('./spec_helper').window
Backbone = window.Backbone
collection = model = null

beforeEach ->
  window.localStorage.clear()
  collection = new Backbone.Collection
    id: 123
    vision: 'crystal'
  collection.url = 'eyes/'
  model = collection.models[0]

describe 'using Backbone.sync directly', ->
  it 'should save and retrieve data', ->
    successCallback = jasmine.createSpy('success')
    errorCallback = jasmine.createSpy('error')
    window.dualsync 'create', model, success: successCallback, error: errorCallback
    expect(window.onlineSync).toHaveBeenCalled()
    expect(successCallback).toHaveBeenCalled()
    expect(errorCallback).not.toHaveBeenCalled()
    expect(Object.keys(window.localStorage.values).length).toBeGreaterThan(0)

    successCallback = jasmine.createSpy('success').andCallFake (resp) ->
      expect(resp.get('vision')).toEqual('crystal')
    errorCallback = jasmine.createSpy('error')
    window.dualsync 'read', model, success: successCallback, error: errorCallback
    expect(window.onlineSync.calls.length).toEqual(2)
    expect(successCallback).toHaveBeenCalled()
    expect(errorCallback).not.toHaveBeenCalled()

describe 'using backbone models and retrieving from local storage', ->
  it "fetches a model after saving it", ->
    saved = false
    runs ->
      model.save {}, success: -> saved = true
    waitsFor (-> saved), "The success callback for 'save' should have been called", 100
    fetched = false
    retrieved_model = new Backbone.Model id: 123
    retrieved_model.collection = collection
    runs ->
      retrieved_model.fetch remote: false, success: -> fetched = true
    waitsFor (-> fetched), "The success callback for 'fetch' should have been called", 100
    runs ->
      expect(retrieved_model.get('vision')).toEqual('crystal')

describe 'using backbone collections and retrieving from local storage', ->
  it 'loads a collection after adding several models to it', ->
    saved = 0
    runs ->
      for id in [1..3]
        new_model = new Backbone.Model id: id
        new_model.collection = collection
        new_model.save {}, success: -> saved += 1
      waitsFor (-> saved == 3), "The success callback for 'save' should have been called for id ##{id}", 100
    fetched = false
    runs ->
      collection.fetch remote: false, success: -> fetched = true
    waitsFor (-> fetched), "The success callback for 'fetch' should have been called", 100
    runs ->
      expect(collection.length).toEqual(3)
      expect(collection.map (model) -> model.id).toEqual [1,2,3]
