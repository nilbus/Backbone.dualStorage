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

spyOnLocalsync = ->
  spyOn(window, 'localsync').andCallFake((method, model, options) -> (options.success?()) unless options.ignoreCallbacks)

describe 'delegating to localsync and onlineSync, and calling the model callbacks', ->
  describe 'dual tier storage', ->
    describe 'create', ->
      it 'delegates to both localsync and onlinesync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          window.dualsync('create', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(window.onlineSync).toHaveBeenCalled()
          expect(window.onlineSync.calls[0].args[0]).toEqual 'create'
          expect(window.localsync).toHaveBeenCalled()
          expect(window.localsync.calls[0].args[0]).toEqual 'create'

    describe 'read', ->
      it 'delegates to both localsync and onlinesync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          window.dualsync('read', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(window.onlineSync).toHaveBeenCalled()
          expect(_(window.onlineSync.calls).any((call) -> call.args[0] == 'read'))
          expect(window.localsync).toHaveBeenCalled()
          expect(_(window.localsync.calls).any((call) -> call.args[0] == 'read'))

    describe 'update', ->
      it 'delegates to both localsync and onlinesync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          window.dualsync('update', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(window.onlineSync).toHaveBeenCalled()
          expect(_(window.onlineSync.calls).any((call) -> call.args[0] == 'update'))
          expect(window.localsync).toHaveBeenCalled()
          expect(_(window.localsync.calls).any((call) -> call.args[0] == 'update'))

    describe 'delete', ->
      it 'delegates to both localsync and onlinesync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          window.dualsync('delete', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(window.onlineSync).toHaveBeenCalled()
          expect(_(window.onlineSync.calls).any((call) -> call.args[0] == 'delete'))
          expect(window.localsync).toHaveBeenCalled()
          expect(_(window.localsync.calls).any((call) -> call.args[0] == 'delete'))

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
    it 'delegates for local models', ->
      spyOnLocalsync()
      ready = false
      runs ->
        model.local = true
        window.onlineSync.reset()
        window.dualsync('update', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(window.localsync).toHaveBeenCalled()
        expect(window.localsync.calls[0].args[0]).toEqual 'update'

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
    spyOnLocalsync()
    ready = undefined
    runs ->
      ready = false
      collection.local = true
      window.dualsync('update', model, success: (-> ready = true), remote: false)
    waitsFor (-> ready), "The success callback should have been called", 100
    runs ->
      expect(window.localsync).toHaveBeenCalled()
      expect(window.localsync.calls.length).toEqual 1
      expect(window.localsync.calls[0].args[2].dirty).toBeFalsy()
    runs ->
      window.localsync.reset()
      ready = false
      collection.local = false
      window.dualsync('update', model, success: (-> ready = true), remote: false)
    waitsFor (-> ready), "The success callback should have been called", 100
    runs ->
      expect(window.localsync).toHaveBeenCalled()
      expect(window.localsync.calls.length).toEqual 1
      expect(window.localsync.calls[0].args[2].dirty).toBeTruthy()

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
