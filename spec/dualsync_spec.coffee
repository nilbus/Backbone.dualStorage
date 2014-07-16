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

spyOnLocalSync = ->
  spyOn(window, 'localSync')
    .andCallFake (method, model, options) ->
      options.success?() unless options.ignoreCallbacks
      $.Deferred().resolve()
  localSync = window.localSync

describe 'delegating to localSync and backboneSync, and calling the model callbacks', ->
  describe 'dual tier storage', ->
    checkMergedAttributesFor = (method, modelToUpdate = model) ->
      spyOnLocalSync()
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
        spyOnLocalSync()
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
        spyOnLocalSync()
        ready = false
        runs ->
          dualSync('read', model, success: (-> ready = true))
        waitsFor (-> ready), "The success callback should have been called", 100
        runs ->
          expect(backboneSync).toHaveBeenCalled()
          expect(_(backboneSync.calls).any((call) -> call.args[0] == 'read')).toBeTruthy()
          expect(localSync).toHaveBeenCalled()
          expect(_(localSync.calls).any((call) -> call.args[0] == 'update')).toBeTruthy()
          expect(_(localSync.calls).every((call) -> call.args[1] instanceof Backbone.Model)).toBeTruthy()

      describe 'for collections', ->
        it 'calls localSync update once for each model', ->
          spyOnLocalSync()
          ready = false
          collectionResponse = [{_id: 12, position: 'arm'}, {_id: 13, position: 'a new model'}]
          runs ->
            dualSync('read', collection, success: (-> ready = true), serverResponse: collectionResponse)
          waitsFor (-> ready), "The success callback should have been called", 100
          runs ->
            expect(backboneSync).toHaveBeenCalled()
            expect(_(backboneSync.calls).any((call) -> call.args[0] == 'read')).toBeTruthy()
            expect(localSync).toHaveBeenCalled()
            updateCalls = _(localSync.calls).select((call) -> call.args[0] == 'update')
            expect(updateCalls.length).toEqual 2
            expect(_(updateCalls).every((call) -> call.args[1] instanceof Backbone.Model)).toBeTruthy()
            updatedModelAttributes = _(updateCalls).map((call) -> call.args[1].attributes)
            expect(updatedModelAttributes[0]).toEqual _id: 12, position: 'arm'
            expect(updatedModelAttributes[1]).toEqual _id: 13, position: 'a new model'

    describe 'update', ->
      it 'delegates to both localSync and backboneSync', ->
        spyOnLocalSync()
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
        spyOnLocalSync()
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
      spyOnLocalSync()
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
          spyOnLocalSync()
          localSync.reset()
          ready = false
          runs ->
            dualSync('read', model, success: (-> ready = true), serverResponse: {side: 'left', _id: 13})
          waitsFor (-> ready), "The success callback should have been called", 100
          runs ->
            expect(localSync.calls[1].args[0]).toEqual 'update'
            expect(localSync.calls[1].args[1].attributes).toEqual position: 'arm', side: 'left', _id: 13

      describe 'for collections', ->
        it 'gets merged with existing attributes on the model with the same id', ->
          spyOnLocalSync()
          localSync.reset()
          ready = false
          runs ->
            dualSync('read', collection, success: (-> ready = true), serverResponse: [{side: 'left', _id: 12}])
          waitsFor (-> ready), "The success callback should have been called", 100
          runs ->
            expect(localSync.calls[2].args[0]).toEqual 'update'
            expect(localSync.calls[2].args[1].attributes).toEqual position: 'arm', side: 'left', _id: 12

    describe 'on create', ->
      it 'gets merged with existing attributes on a model', ->
        spyOnLocalSync()
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
        spyOnLocalSync()
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
    spyOnLocalSync()
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
    spyOnLocalSync()
    dualSync(null, model, {})
    expect(localSync.calls[0].args[2].storeName).toEqual model.url

  it 'prefers the model urlRoot over the url as a store name', ->
    model = new ModelWithAlternateIdAttribute()
    model.local = true
    model.url = '/bacon/bits'
    model.urlRoot = '/bacon'
    spyOnLocalSync()
    dualSync(null, model, {})
    expect(localSync.calls[0].args[2].storeName).toEqual model.urlRoot

  it 'prefers the collection url over the model urlRoot as a store name', ->
    model = new ModelWithAlternateIdAttribute()
    model.local = true
    model.url = '/bacon/bits'
    model.urlRoot = '/bacon'
    model.collection = new Backbone.Collection()
    model.collection.url = '/ranch'
    spyOnLocalSync()
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
    spyOnLocalSync()
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
    spyOnLocalSync()
    dualSync(null, model, {})
    expect(localSync.calls[0].args[2].storeName).toEqual model.collection.storeName

describe 'when to call user-specified success and error callbacks', ->
  it 'uses the success callback when the network is down', ->
    ready = false
    localStorage.setItem 'bones/', "1"
    runs ->
      dualSync('create', model, success: (-> ready = true), errorStatus: 0)
    waitsFor (-> ready), "The success callback should have been called", 100

  it 'uses the success callback when an offline error status is received (e.g. 408)', ->
    ready = false
    localStorage.setItem 'bones/', "1"
    runs ->
      dualSync('create', model, success: (-> ready = true), errorStatus: 408)
    waitsFor (-> ready), "The success callback should have been called", 100

  it 'uses the error callback when an error status is received (e.g. 500)', ->
    ready = false
    runs ->
      dualSync('create', model, error: (-> ready = true), errorStatus: 500)
    waitsFor (-> ready), "The error callback should have been called", 100



  it 'when a model with a temp id has been destroyed', ->
      modelWithTempId = new collection.model();
      modelWithTempId.url = "http://test.ch/";

      modelWithTempId.save({}, { remote: false });
      spyOnLocalsync();

      successSpy = jasmine.createSpy("successHandler");

      modelWithTempId.destroy({ success: successSpy });

      expect(successSpy).toHaveBeenCalled();

  describe 'when offline', ->
    it 'uses the error callback if no existing local store is found', ->
      ready = false
      runs ->
        dualSync('read', model,
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
        dualSync('read', storeModel,
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
        dualSync('read', storeModel,
          success: (-> ready = true)
          errorStatus: 0
        )
        waitsFor (-> ready), "The success callback should have been called", 100
