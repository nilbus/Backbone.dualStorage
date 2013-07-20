{Store, backboneSync, localsync} = window

describe 'bugs, that once fixed, should be moved to the proper spec file and modified to test their inverse', ->
  it 'fails to throw an error when no storeName is provided to the Store constructor,
      even though this will cause problems later.
      The root cause is that the model has no url set; the error should reflect this.', ->
    createNamelessStore = -> new Store
    expect(createNamelessStore).not.toThrow()

  describe 'idAttribute being ignored', ->
    {Role, RoleCollection, collection, model} = {}

    beforeEach ->
      backboneSync.calls = []
      localsync 'clear', {}, success: (->), error: (->)
      collection = new Backbone.Collection
      collection.url = 'eyes/'
      model = new Backbone.Model
      model.collection = collection
      model.set id: 1

    setup = (useIdAttribute) ->
      Role = Backbone.Model.extend
        idAttribute: if useIdAttribute then '_id' else undefined,
        urlRoot: "/roles",
      RoleCollection = Backbone.Collection.extend
        model: Role
        url: "/roles"

    it 'does work with the default idAttribute, id', ->
      setup false
      saved = false
      runs ->
        model.save {vision: 'crystal'}, success: -> saved = true
      waitsFor (-> saved), "The success callback for 'save' should have been called", 100
      fetched = false
      retrievedModel = new Backbone.Model id: 1
      retrievedModel.collection = collection
      runs ->
        retrievedModel.fetch remote: false, success: -> fetched = true
      waitsFor (-> fetched), "The success callback for 'fetch' should have been called", 100
      runs ->
        expect(retrievedModel.get('vision')).toEqual('crystal')


    it 'does not respect idAttribute on models (issue 24)', ->
      setup true
      saved = false
      runs ->
        model.save {}, success: -> saved = true
      waitsFor (-> saved), "The success callback for 'save' should have been called", 100
      fetched = false
      retrievedModel = new Backbone.Model id: 1
      retrievedModel.collection = collection
      runs ->
        retrievedModel.fetch remote: false, success: -> fetched = true
      waitsFor (-> fetched), "The success callback for 'fetch' should have been called", 100
      runs ->
        expect(retrievedModel.get('vision')).toBeUndefined()

