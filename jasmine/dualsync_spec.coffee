{Backbone, backboneSync, localsync, localStorage} = window
{collection, model, ModelWithAlternateIdAttribute} = {}

beforeEach ->
  backboneSync.calls = []
  localStorage.clear()
  ModelWithAlternateIdAttribute = Backbone.Model.extend idAttribute: '_id'
  collection = new Backbone.Collection
  collection.model = ModelWithAlternateIdAttribute
  collection.add
    _id: 12
    position: 'arm'
  collection.url = 'bones/'
  delete collection.remote
  model = collection.models[0]
  delete model.remote

spyOnLocalsync = ->
  spyOn(window, 'localsync')
    .andCallFake (method, model, options) ->
      options.success?() unless options.ignoreCallbacks
  localsync = window.localsync

describe 'delegating to localsync and backboneSync, and calling the model callbacks', ->
  describe 'dual tier storage', ->
    checkMergedAttributesFor = (method, modelToUpdate = model) ->
      spyOnLocalsync()
      originalAttributes = null
      ready = false
      runs ->
        modelToUpdate.set updatedAttribute: 'original value'
        originalAttributes = _.clone(modelToUpdate.attributes)
        serverResponse = _.extend(model.toJSON(), updatedAttribute: 'updated value', newAttribute: 'new value')
        dualsync(method, modelToUpdate, success: (-> ready = true), serverResponse: serverResponse)
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(modelToUpdate.attributes).toEqual originalAttributes
        localsyncedAttributes = _(localsync.calls).map((call) -> call.args[1].attributes)
        updatedAttributes =
          _id: 12
          position: 'arm'
          updatedAttribute: 'updated value'
          newAttribute: 'new value'
        expect(localsyncedAttributes).toContain updatedAttributes

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
          expect(_(localsync.calls).every((call) -> call.args[1] instanceof Backbone.Model)).toBeTruthy()

      it 'merges the response attributes into the model attributes', ->
        checkMergedAttributesFor 'create'

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
          expect(_(localsync.calls).any((call) -> call.args[0] == 'update')).toBeTruthy()
          expect(_(localsync.calls).every((call) -> call.args[1] instanceof Backbone.Model)).toBeTruthy()

      describe 'for collections', ->
        it 'calls localsync update once for each model', ->
          spyOnLocalsync()
          ready = false
          collectionResponse = [{_id: 12, position: 'arm'}, {_id: 13, position: 'a new model'}]
          runs ->
            dualsync('read', collection, success: (-> ready = true), serverResponse: collectionResponse)
          waitsFor (-> ready), "The success callback should have been called", 100
          runs ->
            expect(backboneSync).toHaveBeenCalled()
            expect(_(backboneSync.calls).any((call) -> call.args[0] == 'read')).toBeTruthy()
            expect(localsync).toHaveBeenCalled()
            updateCalls = _(localsync.calls).select((call) -> call.args[0] == 'update')
            expect(updateCalls.length).toEqual 2
            expect(_(updateCalls).every((call) -> call.args[1] instanceof Backbone.Model)).toBeTruthy()
            updatedModelAttributes = _(updateCalls).map((call) -> call.args[1].attributes)
            expect(updatedModelAttributes[0]).toEqual _id: 12, position: 'arm'
            expect(updatedModelAttributes[1]).toEqual _id: 13, position: 'a new model'

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
          expect(_(localsync.calls).every((call) -> call.args[1] instanceof Backbone.Model)).toBeTruthy()

      it 'merges the response attributes into the model attributes', ->
        checkMergedAttributesFor 'update'

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
          expect(_(localsync.calls).every((call) -> call.args[1] instanceof Backbone.Model)).toBeTruthy()

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

  describe 'server response', ->
    describe 'on read', ->
      describe 'for models', ->
        it 'gets merged with existing attributes on a model', ->
          spyOnLocalsync()
          localsync.reset()
          ready = false
          runs ->
            dualsync('read', model, success: (-> ready = true), serverResponse: {side: 'left', _id: 13})
          waitsFor (-> ready), "The success callback should have been called", 100
          runs ->
            expect(localsync.calls[1].args[0]).toEqual 'update'
            expect(localsync.calls[1].args[1].attributes).toEqual position: 'arm', side: 'left', _id: 13

      describe 'for collections', ->
        it 'gets merged with existing attributes on the model with the same id', ->
          spyOnLocalsync()
          localsync.reset()
          ready = false
          runs ->
            dualsync('read', collection, success: (-> ready = true), serverResponse: [{side: 'left', _id: 12}])
          waitsFor (-> ready), "The success callback should have been called", 100
          runs ->
            expect(localsync.calls[2].args[0]).toEqual 'update'
            expect(localsync.calls[2].args[1].attributes).toEqual position: 'arm', side: 'left', _id: 12

    describe 'on create', ->
      it 'gets merged with existing attributes on a model', ->
        spyOnLocalsync()
        localsync.reset()
        ready = false
        runs ->
          dualsync('create', model, success: (-> ready = true), serverResponse: {side: 'left', _id: 13})
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(localsync.calls[0].args[0]).toEqual 'create'
          expect(localsync.calls[0].args[1].attributes).toEqual position: 'arm', side: 'left', _id: 13

    describe 'on update', ->
      it 'gets merged with existing attributes on a model', ->
        spyOnLocalsync()
        localsync.reset()
        ready = false
        runs ->
          dualsync('update', model, success: (-> ready = true), serverResponse: {side: 'left', _id: 13})
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(localsync.calls[0].args[0]).toEqual 'update'
          expect(localsync.calls[0].args[1].attributes).toEqual position: 'arm', side: 'left', _id: 13

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
      new ModelWithAlternateIdAttribute(parsedRemote: true)
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

describe 'storeName selection', ->
  it 'uses the model url as a store name', ->
    model = new ModelWithAlternateIdAttribute()
    model.local = true
    model.url = '/bacon/bits'
    spyOnLocalsync()
    dualsync(null, model, {})
    expect(localsync.calls[0].args[2].storeName).toEqual model.url

  it 'prefers the model urlRoot over the url as a store name', ->
    model = new ModelWithAlternateIdAttribute()
    model.local = true
    model.url = '/bacon/bits'
    model.urlRoot = '/bacon'
    spyOnLocalsync()
    dualsync(null, model, {})
    expect(localsync.calls[0].args[2].storeName).toEqual model.urlRoot

  it 'prefers the collection url over the model urlRoot as a store name', ->
    model = new ModelWithAlternateIdAttribute()
    model.local = true
    model.url = '/bacon/bits'
    model.urlRoot = '/bacon'
    model.collection = new Backbone.Collection()
    model.collection.url = '/ranch'
    spyOnLocalsync()
    dualsync(null, model, {})
    expect(localsync.calls[0].args[2].storeName).toEqual model.collection.url

  it 'prefers the model storeName over the collection url as a store name', ->
    model = new ModelWithAlternateIdAttribute()
    model.local = true
    model.url = '/bacon/bits'
    model.urlRoot = '/bacon'
    model.collection = new Backbone.Collection()
    model.collection.url = '/ranch'
    model.storeName = 'melted cheddar'
    spyOnLocalsync()
    dualsync(null, model, {})
    expect(localsync.calls[0].args[2].storeName).toEqual model.storeName

  it 'prefers the collection storeName over the model storeName as a store name', ->
    model = new ModelWithAlternateIdAttribute()
    model.local = true
    model.url = '/bacon/bits'
    model.urlRoot = '/bacon'
    model.collection = new Backbone.Collection()
    model.collection.url = '/ranch'
    model.storeName = 'melted cheddar'
    model.collection.storeName = 'ketchup'
    spyOnLocalsync()
    dualsync(null, model, {})
    expect(localsync.calls[0].args[2].storeName).toEqual model.collection.storeName

describe 'when to call user-specified success and error callbacks', ->
  it 'uses the success callback when the network is down', ->
    ready = false
    localStorage.setItem 'bones/', "1"
    runs ->
      dualsync('create', model, success: (-> ready = true), errorStatus: 0)
    waitsFor (-> ready), "The success callback should have been called", 100

  it 'uses the success callback when an offline error status is received (e.g. 408)', ->
    ready = false
    localStorage.setItem 'bones/', "1"
    runs ->
      dualsync('create', model, success: (-> ready = true), errorStatus: 408)
    waitsFor (-> ready), "The success callback should have been called", 100

  it 'uses the error callback when an error status is received (e.g. 500)', ->
    ready = false
    runs ->
      dualsync('create', model, error: (-> ready = true), errorStatus: 500)
    waitsFor (-> ready), "The error callback should have been called", 100

  describe 'when offline', ->
    it 'uses the error callback if no existing local store is found', ->
      ready = false
      runs ->
        dualsync('read', model,
          error: (-> ready = true)
          errorStatus: 0
        )
      waitsFor (-> ready), "The error callback should have been called", 100

    it 'uses the success callback if the store exists with data', ->
      storeModel = model.clone()
      storeModel.storeName = 'store-exists'
      localStorage.setItem storeModel.storeName, "1,2,3"
      ready = false
      runs ->
        dualsync('read', storeModel,
          success: (-> ready = true)
          errorStatus: 0
        )
        waitsFor (-> ready), "The success callback should have been called", 100

    it 'success if server errors and Store exists with no entries', ->
      storeModel = model.clone()
      storeModel.storeName = 'store-exists'
      localStorage.setItem storeModel.storeName, ""
      ready = false
      runs ->
        dualsync('read', storeModel,
          success: (-> ready = true)
          errorStatus: 0
        )
        waitsFor (-> ready), "The success callback should have been called", 100
