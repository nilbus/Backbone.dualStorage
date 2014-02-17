{backboneSync, localsync, dualSync, localStorage} = window
{collection, model} = {}

beforeEach ->
  backboneSync.calls = []
  localsync 'clear', {}, ignoreCallbacks: true, storeName: 'eyes/'
  collection = new Backbone.Collection
    id: 123
    vision: 'crystal'
  collection.url = 'eyes/'
  model = collection.models[0]

describe 'using Backbone.sync directly', ->
  it 'should save and retrieve data', ->
    {successCallback, errorCallback} = {}
    saved = false
    runs ->
      localStorage.clear()
      successCallback = jasmine.createSpy('success').andCallFake -> saved = true
      errorCallback = jasmine.createSpy('error')
      dualsync 'create', model, success: successCallback, error: errorCallback
    waitsFor (-> saved), "The success callback for 'create' should have been called", 100
    runs ->
      expect(backboneSync.calls.length).toEqual(1)
      expect(successCallback).toHaveBeenCalled()
      expect(errorCallback).not.toHaveBeenCalled()
      expect(localStorage.length).toBeGreaterThan(0)

    fetched = false
    runs ->
      successCallback = jasmine.createSpy('success').andCallFake callbackTranslator.forBackboneCaller (resp) ->
        fetched = true
        expect(resp.vision).toEqual('crystal')
      errorCallback = jasmine.createSpy('error')
      dualsync 'read', model, success: successCallback, error: errorCallback
    waitsFor (-> fetched), "The success callback for 'read' should have been called", 100
    runs ->
      expect(backboneSync.calls.length).toEqual(2)
      expect(successCallback).toHaveBeenCalled()
      expect(errorCallback).not.toHaveBeenCalled()

describe 'using backbone models and retrieving from local storage', ->
  it "fetches a model offline after saving it online", ->
    saved = false
    runs ->
      model.save {}, success: -> saved = true
    waitsFor (-> saved), "The success callback for 'save' should have been called", 100
    fetched = false
    retrievedModel = new Backbone.Model id: 123
    retrievedModel.collection = collection
    runs ->
      retrievedModel.fetch remote: false, success: -> fetched = true
    waitsFor (-> fetched), "The success callback for 'fetch' should have been called", 100
    runs ->
      expect(retrievedModel.get('vision')).toEqual('crystal')

  it "works with an idAttribute other than 'id'", ->
    class NonstandardModel extends Backbone.Model
      idAttribute: 'eyeDee'
      url: 'eyes/'
    model = new NonstandardModel eyeDee: 123, vision: 'crystal'
    saved = false
    runs ->
      model.save {}, success: -> saved = true
    waitsFor (-> saved), "The success callback for 'save' should have been called", 100
    fetched = false
    retrievedModel = new NonstandardModel eyeDee: 123
    runs ->
      retrievedModel.fetch remote: false, success: -> fetched = true
    waitsFor (-> fetched), "The success callback for 'fetch' should have been called", 100
    runs ->
      expect(retrievedModel.get('vision')).toEqual('crystal')

describe 'using backbone collections and retrieving from local storage', ->
  it 'loads a collection after adding several models to it', ->
    saved = 0
    runs ->
      for id in [1..3]
        newModel = new Backbone.Model id: id
        newModel.collection = collection
        newModel.save {}, success: -> saved += 1
      waitsFor (-> saved == 3), "The success callback for 'save' should have been called for id ##{id}", 100
    fetched = false
    runs ->
      collection.fetch remote: false, success: -> fetched = true
    waitsFor (-> fetched), "The success callback for 'fetch' should have been called", 100
    runs ->
      expect(collection.length).toEqual(3)
      expect(collection.map (model) -> model.id).toEqual [1,2,3]

describe 'success and error callback parameters', ->
  it "passes back the response into the remote method's callback", ->
    callbackResponse = null
    runs ->
      model.remote = true
      model.fetch success: (args...) -> callbackResponse = args
    waitsFor (-> callbackResponse), "The success callback for 'fetch' should have been called", 100
    runs ->
      expect(callbackResponse[0]).toEqual model
      expect(callbackResponse[1]).toEqual model.attributes
