{collection, model} = {}
beforeEach ->
  window.backboneSync.calls = []
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

describe 'delegating to localsync and backboneSync, and calling the model callbacks', ->
  describe 'dual tier storage', ->
    describe 'create', ->
      it 'delegates to both localsync and backboneSync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          window.dualsync('create', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(window.backboneSync).toHaveBeenCalled()
          expect(window.backboneSync.calls[0].args[0]).toEqual 'create'
          expect(window.localsync).toHaveBeenCalled()
          expect(window.localsync.calls[0].args[0]).toEqual 'create'

    describe 'read', ->
      it 'delegates to both localsync and backboneSync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          window.dualsync('read', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(window.backboneSync).toHaveBeenCalled()
          expect(_(window.backboneSync.calls).any((call) -> call.args[0] == 'read')).toBeTruthy()
          expect(window.localsync).toHaveBeenCalled()
          expect(_(window.localsync.calls).any((call) -> call.args[0] == 'create')).toBeTruthy()

    describe 'update', ->
      it 'delegates to both localsync and backboneSync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          window.dualsync('update', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(window.backboneSync).toHaveBeenCalled()
          expect(_(window.backboneSync.calls).any((call) -> call.args[0] == 'update')).toBeTruthy()
          expect(window.localsync).toHaveBeenCalled()
          expect(_(window.localsync.calls).any((call) -> call.args[0] == 'update')).toBeTruthy()

    describe 'delete', ->
      it 'delegates to both localsync and backboneSync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          window.dualsync('delete', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(window.backboneSync).toHaveBeenCalled()
          expect(_(window.backboneSync.calls).any((call) -> call.args[0] == 'delete')).toBeTruthy()
          expect(window.localsync).toHaveBeenCalled()
          expect(_(window.localsync.calls).any((call) -> call.args[0] == 'delete')).toBeTruthy()

  describe 'respects the remote only attribute on models', ->
    it 'delegates for remote models', ->
      ready = false
      runs ->
        model.remote = true
        window.dualsync('create', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(window.backboneSync).toHaveBeenCalled()
        expect(window.backboneSync.calls[0].args[0]).toEqual 'create'

    it 'delegates for remote collections', ->
      ready = false
      runs ->
        collection.remote = true
        window.dualsync('read', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(window.backboneSync).toHaveBeenCalled()
        expect(window.backboneSync.calls[0].args[0]).toEqual 'read'

  describe 'respects the local only attribute on models', ->
    it 'delegates for local models', ->
      spyOnLocalsync()
      ready = false
      runs ->
        model.local = true
        window.backboneSync.reset()
        window.dualsync('update', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(window.localsync).toHaveBeenCalled()
        expect(window.localsync.calls[0].args[0]).toEqual 'update'

    it 'delegates for local collections', ->
      ready = false
      runs ->
        collection.local = true
        window.backboneSync.reset()
        window.dualsync('delete', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(window.backboneSync).not.toHaveBeenCalled()

  it 'respects the remote: false sync option', ->
    ready = false
    runs ->
      window.backboneSync.reset()
      window.dualsync('create', model, success: (-> ready = true), remote: false)
    waitsFor (-> ready), "The success callback should have been called", 100
    runs ->
      expect(window.backboneSync).not.toHaveBeenCalled()

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
      window.dualsync 'read', model, success: (callback_args...) ->
        response = callback_args
    waitsFor (-> response), "The success callback should have been called", 100
    runs ->
      expect(response[0].get('parsedRemote') || response[1].get('parsedRemote')).toBeTruthy()
