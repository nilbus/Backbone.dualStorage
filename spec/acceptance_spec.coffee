{backboneSync, localSync, dualSync, localStorage} = window
{Collection, Model, collection, model} = {}

describe 'Backbone.dualStorage', ->
  @timeout 10

  beforeEach ->
    backboneSync.calls = []
    localStorage.clear()
    class Model extends Backbone.Model
      idAttribute: '_id'
      urlRoot: 'eyes/'
    class Collection extends Backbone.Collection
      model: Model
      url: Model::urlRoot
    collection = new Collection
      _id: 123
      vision: 'crystal'
    model = collection.models[0]

  describe 'using backbone models and retrieving from local storage', ->
    it "fetches a model offline after saving it online", (done) ->
      saved = $.Deferred()
      model.save {}, success: ->
        saved.resolve()
      saved.done ->
        fetched = $.Deferred()
        retrievedModel = new Model _id: 123
        retrievedModel.fetch remote: false, success: ->
          fetched.resolve()
        fetched.done ->
          expect(retrievedModel.get('vision')).to.equal('crystal')
          done()

  describe 'using backbone collections and retrieving from local storage', ->
    it 'loads a collection after adding several models to it', (done) ->
      allSaved = for id in [1..3]
        saved = $.Deferred()
        newModel = new Model _id: id
        newModel.save {}, success: -> saved.resolve()
        saved
      $.when(allSaved).done ->
        fetched = $.Deferred()
        collection.fetch remote: false, success: -> fetched.resolve()
        fetched.done ->
          expect(collection.length).to.equal(3)
          expect(collection.map (model) -> model.id).to.eql [1,2,3]
          done()

  describe 'success and error callback parameters', ->
    it "passes back the response into the remote method's callback", ->
      fetched = $.Deferred()
      model.remote = true
      model.fetch success: (args...) -> fetched.resolve(args)
      fetched.done (callbackResponse) ->
        expect(callbackResponse[0]).to.equal model
        expect(callbackResponse[1]).to.eql model.attributes
