{Backbone, backboneSync, localsync, localStorage} = window
{collection, model} = {}

beforeEach ->
  backboneSync.calls = []
  localStorage.clear()
  collection = new Backbone.Collection
    id: 12
    position: 'arm'
  collection.url = 'bones/'
  delete collection.remote
  model = collection.models[0]
  delete model.remote

spyOnLocalsync = ->
  spyOn(window, 'localsync').andCallFake((method, model, options) -> (options.success?()) unless options.ignoreCallbacks)
  localsync = window.localsync

spyOnLocalsyncNonDirty = (notifyLastModel) ->
  spyOn(window, 'localsync')
    .andCallFake (method, model, options) ->
      if _.isFunction notifyLastModel
        notifyLastModel model
      return false if method is 'hasDirtyOrDestroyed'

describe 'delegating to localsync and backboneSync, and calling the model callbacks', ->
  describe 'dual tier storage', ->
    describe 'create', ->
      it 'delegates to both localsync and backboneSync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          dualsync('create', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(backboneSync).toHaveBeenCalled()
          expect(backboneSync.calls[0].args[0]).toEqual 'create'
          expect(localsync).toHaveBeenCalled()
          expect(localsync.calls[0].args[0]).toEqual 'create'

      it 'always calls localsync with a backbone model', ->
        spyOnLocalsync()
        ready = false
        runs ->
          dualsync 'create', model, success: (-> ready = true)
        waitsFor (-> ready), "success callback should have been called", 100
        runs ->
          expect(_(localsync.calls).every((call) -> call.args[1] instanceof Backbone.Model))
            .toBeTruthy()

    describe 'read', ->
      it 'delegates to both localsync and backboneSync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          dualsync('read', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(backboneSync).toHaveBeenCalled()
          expect(_(backboneSync.calls).any((call) -> call.args[0] == 'read')).toBeTruthy()
          expect(localsync).toHaveBeenCalled()
          expect(_(localsync.calls).any((call) -> call.args[0] == 'create')).toBeTruthy()

      it 'always calls localsync with a backbone model when an object is received', ->
        spyOnLocalsyncNonDirty()
        ready = false
        runs ->
          dualsync 'read', model, success: (-> ready = true)
        waitsFor (-> ready), "success callback should have been called", 100
        runs ->
          expect(_(localsync.calls).every((call) -> call.args[1] instanceof Backbone.Model))
            .toBeTruthy()

      it 'always calls localsync with a backbone model when an array is received', ->
        {ready, lastCalledWith} = {}
        # Note: Need to go this hacky way because jasmine's spy.mostRecentCall
        # was not reporting the last called args properly.
        spyOnLocalsyncNonDirty (lastModel) -> lastCalledWith = lastModel
        runs ->
          dualsync 'read', model, success: (-> ready = true), serverReturnedAttributes: collection.toJSON()
        waitsFor (-> ready), "success callback should have been called", 100
        runs ->
          expect(lastCalledWith instanceof Backbone.Model).toBeTruthy()

    describe 'update', ->
      it 'delegates to both localsync and backboneSync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          dualsync('update', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(backboneSync).toHaveBeenCalled()
          expect(_(backboneSync.calls).any((call) -> call.args[0] == 'update')).toBeTruthy()
          expect(localsync).toHaveBeenCalled()
          expect(_(localsync.calls).any((call) -> call.args[0] == 'update')).toBeTruthy()

      it 'merges updates from the server response into the model attributes on server-persisted models', ->
        spyOnLocalsync()
        ready = false
        runs ->
          dualsync('update', model, success: (-> ready = true), serverReturnedAttributes: {updated: 'by the server'})
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          mergedAttributes =
            id: 12
            position: 'arm'
            updated: 'by the server'
          expect(localsync.calls[0].args[1].attributes).toEqual(mergedAttributes)

      it 'always calls localsync with a backbone model for non-syncronized offline models', ->
        store = new window.Store 'bones/'

        newModel = store.create new Backbone.Model
          position: 'Hand'
        newModel.url = 'bones/'
        console.log newModel

        spyOnLocalsync()
        ready = false
        runs ->
          dualsync 'update', newModel, success: (-> ready = true)
        waitsFor (-> ready), "success callback should have been called", 100
        runs ->
          expect(_(localsync.calls).every((call) -> call.args[1] instanceof Backbone.Model))
            .toBeTruthy()

    describe 'delete', ->
      it 'delegates to both localsync and backboneSync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          dualsync('delete', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(backboneSync).toHaveBeenCalled()
          expect(_(backboneSync.calls).any((call) -> call.args[0] == 'delete')).toBeTruthy()
          expect(localsync).toHaveBeenCalled()
          expect(_(localsync.calls).any((call) -> call.args[0] == 'delete')).toBeTruthy()

  describe 'respects the remote only attribute on models', ->
    it 'delegates for remote models', ->
      ready = false
      runs ->
        model.remote = true
        dualsync('create', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(backboneSync).toHaveBeenCalled()
        expect(backboneSync.calls[0].args[0]).toEqual 'create'

    it 'delegates for remote collections', ->
      ready = false
      runs ->
        collection.remote = true
        dualsync('read', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(backboneSync).toHaveBeenCalled()
        expect(backboneSync.calls[0].args[0]).toEqual 'read'

  describe 'respects the local only attribute on models', ->
    it 'delegates for local models', ->
      spyOnLocalsync()
      ready = false
      runs ->
        model.local = true
        backboneSync.reset()
        dualsync('update', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(localsync).toHaveBeenCalled()
        expect(localsync.calls[0].args[0]).toEqual 'update'

    it 'delegates for local collections', ->
      ready = false
      runs ->
        collection.local = true
        backboneSync.reset()
        dualsync('delete', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(backboneSync).not.toHaveBeenCalled()

  it 'respects the remote: false sync option', ->
    ready = false
    runs ->
      backboneSync.reset()
      dualsync('create', model, success: (-> ready = true), remote: false)
    waitsFor (-> ready), "The success callback should have been called", 100
    runs ->
      expect(backboneSync).not.toHaveBeenCalled()

describe 'offline storage', ->
  it 'marks records dirty when options.remote is false, except if the model/collection is marked as local', ->
    spyOnLocalsync()
    ready = undefined
    runs ->
      ready = false
      collection.local = true
      dualsync('update', model, success: (-> ready = true), remote: false)
    waitsFor (-> ready), "The success callback should have been called", 100
    runs ->
      expect(localsync).toHaveBeenCalled()
      expect(localsync.calls.length).toEqual 1
      expect(localsync.calls[0].args[2].dirty).toBeFalsy()
    runs ->
      localsync.reset()
      ready = false
      collection.local = false
      dualsync('update', model, success: (-> ready = true), remote: false)
    waitsFor (-> ready), "The success callback should have been called", 100
    runs ->
      expect(localsync).toHaveBeenCalled()
      expect(localsync.calls.length).toEqual 1
      expect(localsync.calls[0].args[2].dirty).toBeTruthy()

describe 'dualStorage hooks', ->
  beforeEach ->
    model.parseBeforeLocalSave = ->
      new Backbone.Model(parsedRemote: true)
    ready = false
    runs ->
      dualsync 'create', model, success: (-> ready = true)
    waitsFor (-> ready), "The success callback should have been called", 100

  it 'filters read responses through parseBeforeLocalSave when defined on the model or collection', ->
    response = null
    runs ->
      dualsync 'read', model, success: (callback_args...) ->
        response = callback_args
    waitsFor (-> response), "The success callback should have been called", 100
    runs ->
      expect(response[0].get('parsedRemote') || response[1].get('parsedRemote')).toBeTruthy()
