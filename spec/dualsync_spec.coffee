{Backbone, backboneSync, localSync, localStorage} = window
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
  spyOn(window, 'localSync')
    .andCallFake (method, model, options) ->
      options.success?() unless options.ignoreCallbacks
      $.Deferred().resolve();
  localSync = window.localSync

describe 'delegating to localSync and backboneSync, and calling the model callbacks', ->
  describe 'dual tier storage', ->
    checkMergedAttributesFor = (method, modelToUpdate = model) ->
      spyOnLocalsync()
      originalAttributes = null
      ready = false
      runs ->
        modelToUpdate.set updatedAttribute: 'original value'
        originalAttributes = _.clone(modelToUpdate.attributes)
        serverResponse = _.extend(model.toJSON(), updatedAttribute: 'updated value', newAttribute: 'new value')
        dualSync(method, modelToUpdate, success: (-> ready = true), serverResponse: serverResponse)
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(modelToUpdate.attributes).toEqual originalAttributes
        localSyncedAttributes = _(localSync.calls).map((call) -> call.args[1].attributes)
        updatedAttributes =
          _id: 12
          position: 'arm'
          updatedAttribute: 'updated value'
          newAttribute: 'new value'
        expect(localSyncedAttributes).toContain updatedAttributes

    describe 'create', ->
      it 'delegates to both localSync and backboneSync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          dualSync('create', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(backboneSync).toHaveBeenCalled()
          expect(backboneSync.calls[0].args[0]).toEqual 'create'
          expect(localSync).toHaveBeenCalled()
          expect(localSync.calls[0].args[0]).toEqual 'create'
          expect(_(localSync.calls).every((call) -> call.args[1] instanceof Backbone.Model)).toBeTruthy()

      it 'merges the response attributes into the model attributes', ->
        checkMergedAttributesFor 'create'

    describe 'read', ->
      it 'delegates to both localSync and backboneSync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          dualSync('read', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(backboneSync).toHaveBeenCalled()
          expect(_(backboneSync.calls).any((call) -> call.args[0] == 'read')).toBeTruthy()
          expect(localSync).toHaveBeenCalled()
          expect(_(localSync.calls).any((call) -> call.args[0] == 'create')).toBeTruthy()
          expect(_(localSync.calls).every((call) -> call.args[1] instanceof Backbone.Model)).toBeTruthy()

      describe 'for collections', ->
        it 'calls localSync create once for each model', ->
          spyOnLocalsync()
          ready = false
          collectionResponse = [{_id: 12, position: 'arm'}, {_id: 13, position: 'a new model'}]
          runs ->
            dualSync('read', collection, success: (-> ready = true), serverResponse: collectionResponse)
          waitsFor (-> ready), "The success callback should have been called", 100
          runs ->
            expect(backboneSync).toHaveBeenCalled()
            expect(_(backboneSync.calls).any((call) -> call.args[0] == 'read')).toBeTruthy()
            expect(localSync).toHaveBeenCalled()
            createCalls = _(localSync.calls).select((call) -> call.args[0] == 'create')
            expect(createCalls.length).toEqual 2
            expect(_(createCalls).every((call) -> call.args[1] instanceof Backbone.Model)).toBeTruthy()
            createdModelAttributes = _(createCalls).map((call) -> call.args[1].attributes)
            expect(createdModelAttributes[0]).toEqual _id: 12, position: 'arm'
            expect(createdModelAttributes[1]).toEqual _id: 13, position: 'a new model'

    describe 'update', ->
      it 'delegates to both localSync and backboneSync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          dualSync('update', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(backboneSync).toHaveBeenCalled()
          expect(_(backboneSync.calls).any((call) -> call.args[0] == 'update')).toBeTruthy()
          expect(localSync).toHaveBeenCalled()
          expect(_(localSync.calls).any((call) -> call.args[0] == 'update')).toBeTruthy()
          expect(_(localSync.calls).every((call) -> call.args[1] instanceof Backbone.Model)).toBeTruthy()

      it 'merges the response attributes into the model attributes', ->
        checkMergedAttributesFor 'update'

    describe 'delete', ->
      it 'delegates to both localSync and backboneSync', ->
        spyOnLocalsync()
        ready = false
        runs ->
          dualSync('delete', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(backboneSync).toHaveBeenCalled()
          expect(_(backboneSync.calls).any((call) -> call.args[0] == 'delete')).toBeTruthy()
          expect(localSync).toHaveBeenCalled()
          expect(_(localSync.calls).any((call) -> call.args[0] == 'delete')).toBeTruthy()
          expect(_(localSync.calls).every((call) -> call.args[1] instanceof Backbone.Model)).toBeTruthy()

  describe 'respects the remote only attribute on models', ->
    it 'delegates for remote models', ->
      ready = false
      runs ->
        model.remote = true
        dualSync('create', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(backboneSync).toHaveBeenCalled()
        expect(backboneSync.calls[0].args[0]).toEqual 'create'

    it 'delegates for remote collections', ->
      ready = false
      runs ->
        collection.remote = true
        dualSync('read', model, success: (-> ready = true))
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
        dualSync('update', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(localSync).toHaveBeenCalled()
        expect(localSync.calls[0].args[0]).toEqual 'update'

    it 'delegates for local collections', ->
      ready = false
      runs ->
        collection.local = true
        backboneSync.reset()
        dualSync('delete', model, success: (-> ready = true))
      waitsFor (-> ready), "The success callback should have been called", 100
      runs ->
        expect(backboneSync).not.toHaveBeenCalled()

  it 'respects the remote: false sync option', ->
    ready = false
    runs ->
      backboneSync.reset()
      dualSync('create', model, success: (-> ready = true), remote: false)
    waitsFor (-> ready), "The success callback should have been called", 100
    runs ->
      expect(backboneSync).not.toHaveBeenCalled()

  describe 'server response', ->
    describe 'on read', ->
      describe 'for models', ->
        it 'gets merged with existing attributes on a model', ->
          spyOnLocalsync()
          localSync.reset()
          ready = false
          runs ->
            dualSync('read', model, success: (-> ready = true), serverResponse: {side: 'left', _id: 13})
          waitsFor (-> ready), "The success callback should have been called", 100
          runs ->
            window.x = localSync
            expect(localSync.calls[2].args[0]).toEqual 'create'
            expect(localSync.calls[2].args[1].attributes).toEqual position: 'arm', side: 'left', _id: 13

      describe 'for collections', ->
        it 'gets merged with existing attributes on the model with the same id', ->
          spyOnLocalsync()
          localSync.reset()
          ready = false
          runs ->
            dualSync('read', collection, success: (-> ready = true), serverResponse: [{side: 'left', _id: 12}])
          waitsFor (-> ready), "The success callback should have been called", 100
          runs ->
            expect(localSync.calls[2].args[0]).toEqual 'create'
            expect(localSync.calls[2].args[1].attributes).toEqual position: 'arm', side: 'left', _id: 12

    describe 'on create', ->
      it 'gets merged with existing attributes on a model', ->
        spyOnLocalsync()
        localSync.reset()
        ready = false
        runs ->
          dualSync('create', model, success: (-> ready = true), serverResponse: {side: 'left', _id: 13})
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(localSync.calls[0].args[0]).toEqual 'create'
          expect(localSync.calls[0].args[1].attributes).toEqual position: 'arm', side: 'left', _id: 13

    describe 'on update', ->
      it 'gets merged with existing attributes on a model', ->
        spyOnLocalsync()
        localSync.reset()
        ready = false
        runs ->
          dualSync('update', model, success: (-> ready = true), serverResponse: {side: 'left', _id: 13})
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(localSync.calls[0].args[0]).toEqual 'update'
          expect(localSync.calls[0].args[1].attributes).toEqual position: 'arm', side: 'left', _id: 13

describe 'offline storage', ->
  it 'marks records dirty when options.remote is false, except if the model/collection is marked as local', ->
    spyOnLocalsync()
    ready = undefined
    runs ->
      ready = false
      collection.local = true
      dualSync('update', model, success: (-> ready = true), remote: false)
    waitsFor (-> ready), "The success callback should have been called", 100
    runs ->
      expect(localSync).toHaveBeenCalled()
      expect(localSync.calls.length).toEqual 1
      expect(localSync.calls[0].args[2].dirty).toBeFalsy()
    runs ->
      localSync.reset()
      ready = false
      collection.local = false
      dualSync('update', model, success: (-> ready = true), remote: false)
    waitsFor (-> ready), "The success callback should have been called", 100
    runs ->
      expect(localSync).toHaveBeenCalled()
      expect(localSync.calls.length).toEqual 1
      expect(localSync.calls[0].args[2].dirty).toBeTruthy()

describe 'dualStorage hooks', ->
  beforeEach ->
    model.parseBeforeLocalSave = ->
      new ModelWithAlternateIdAttribute(parsedRemote: true)
    ready = false
    runs ->
      dualSync 'create', model, success: (-> ready = true)
    waitsFor (-> ready), "The success callback should have been called", 100

  it 'filters read responses through parseBeforeLocalSave when defined on the model or collection', ->
    response = null
    runs ->
      dualSync 'read', model, success: (callback_args...) ->
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
    dualSync(null, model, {})
    expect(localSync.calls[0].args[2].storeName).toEqual model.url

  it 'prefers the model urlRoot over the url as a store name', ->
    model = new ModelWithAlternateIdAttribute()
    model.local = true
    model.url = '/bacon/bits'
    model.urlRoot = '/bacon'
    spyOnLocalsync()
    dualSync(null, model, {})
    expect(localSync.calls[0].args[2].storeName).toEqual model.urlRoot

  it 'prefers the collection url over the model urlRoot as a store name', ->
    model = new ModelWithAlternateIdAttribute()
    model.local = true
    model.url = '/bacon/bits'
    model.urlRoot = '/bacon'
    model.collection = new Backbone.Collection()
    model.collection.url = '/ranch'
    spyOnLocalsync()
    dualSync(null, model, {})
    expect(localSync.calls[0].args[2].storeName).toEqual model.collection.url

  it 'prefers the model storeName over the collection url as a store name', ->
    model = new ModelWithAlternateIdAttribute()
    model.local = true
    model.url = '/bacon/bits'
    model.urlRoot = '/bacon'
    model.collection = new Backbone.Collection()
    model.collection.url = '/ranch'
    model.storeName = 'melted cheddar'
    spyOnLocalsync()
    dualSync(null, model, {})
    expect(localSync.calls[0].args[2].storeName).toEqual model.storeName

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
    dualSync(null, model, {})
    expect(localSync.calls[0].args[2].storeName).toEqual model.collection.storeName
