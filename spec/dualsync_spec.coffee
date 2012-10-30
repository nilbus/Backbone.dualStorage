window = require('./spec_helper').window
Backbone = window.Backbone
_ = window._

{collection, model} = {}
beforeEach ->
  window.onlineSync.calls = []
  window.localStorage.clear()
  collection = new Backbone.Collection
    id: 12
    position: 'arm'
  collection.url = 'bones/'
  delete collection.remote
  model = collection.models[0]
  delete model.remote

describe 'delegating to localsync and onlineSync, and calling the model callbacks', ->
  describe 'dual tier storage', ->
    describe 'create', ->
    describe 'read', ->
    describe 'update', ->
    describe 'delete', ->

  describe 'respects the remote only attribute on models', ->
    it 'delegates for remote models', ->
      ready = false
      runs ->
        model.remote = true
        window.dualsync('create', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(window.onlineSync).toHaveBeenCalled()
        expect(window.onlineSync.calls[0].args[0]).toEqual 'create'

    it 'delegates for remote collections', ->
      ready = false
      runs ->
        collection.remote = true
        window.dualsync('read', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(window.onlineSync).toHaveBeenCalled()
        expect(window.onlineSync.calls[0].args[0]).toEqual 'read'

  describe 'respects the local only attribute on models', ->
    ## Spying on window.localsync does not make the spy available in the vm.
    ## Instead, check that the onlineSync spy is not called in these and other tests below.
    it 'delegates for local models', ->
      # spyOn window, 'localsync'
      ready = false
      runs ->
        model.local = true
        window.onlineSync.reset()
        window.dualsync('update', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        # expect(window.localsync).toHaveBeenCalled()
        # expect(window.localsync.calls[0].args[0]).toEqual 'update'
        expect(window.onlineSync).not.toHaveBeenCalled()

    it 'delegates for local collections', ->
      ready = false
      runs ->
        collection.local = true
        window.onlineSync.reset()
        window.dualsync('delete', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(window.onlineSync).not.toHaveBeenCalled()

  it 'respects the remote: false sync option', ->
    ready = false
    runs ->
      window.onlineSync.reset()
      window.dualsync('create', model, success: (-> ready = true), remote: false)
    waitsFor (-> ready), "The success callback should have been called", 100
    runs ->
      expect(window.onlineSync).not.toHaveBeenCalled()

describe 'offline storage', ->
  it 'marks records dirty when options.remote is false, except if the model/collection is marked as local', ->
    ready = undefined
    runs ->
      ready = false
      collection.local = true
      window.dualsync('update', model, success: (-> ready = true), remote: false)
    waitsFor (-> ready), "The success callback should have been called", 100
    runs ->
      # Using localsync instead of mocking it (see comment above)
      expect(window.localsync('hasDirtyOrDestroyed', model, storeName: collection.url, ignoreCallbacks: true)).toBeFalsy()
      collection.local = false
      window.dualsync('update', model, success: (-> ready = true), remote: false)
    waitsFor (-> ready), "The success callback should have been called", 100
    runs ->
      expect(window.localsync('hasDirtyOrDestroyed', model, storeName: collection.url, ignoreCallbacks: true)).toBeTruthy()

describe 'dualStorage hooks', ->
  beforeEach ->
    model.parseBeforeLocalSave = ->
      new Backbone.Model(parsedRemote: true)
    ready = false
    runs ->
      window.dualsync 'create', model, success: (-> ready = true)
    waitsFor (-> ready), "The success callback should have been called", 100

  it 'filters read responses through parseBeforeLocalSave when defined on the model or collection', ->
    response = null
    runs ->
      window.dualsync 'read', model, success: (callback_response) -> response = callback_response
    waitsFor (-> response), "The success callback should have been called", 100
    runs ->
      expect(response.get('parsedRemote')).toBeTruthy()
