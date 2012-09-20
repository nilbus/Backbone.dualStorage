helper = require('./spec_helper')
window = helper.window
Backbone = window.Backbone

describe 'integration', ->
  collection = new Backbone.Collection
    id: 123
    vision: 'crystal'
  collection.url = 'eyes/'
  model = collection.models[0]

  beforeEach ->
    window.localStorage.clear()

  it 'aliases Backbone.sync to onlineSync', ->
    expect(window.onlineSync).toBeDefined()
    expect(window.onlineSync.identity).toEqual('sync')

  it 'should save and retrieve data using Backbone.sync directly', ->
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

  it "should fetch a model's data after saving it", ->
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

