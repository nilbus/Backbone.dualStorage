{backboneSync, localSync, dualSync, localStorage} = window
{Collection, Model} = {}

describe 'storeName', ->
  @timeout 100

  beforeEach ->
    localStorage.clear()
    class Model extends Backbone.Model
      idAttribute: '_id'
      urlRoot: 'things/'
    class Collection extends Backbone.Collection
      model: Model
      url: Model::urlRoot

  it 'uses the same store for models with the same storeName', (done) ->
    class OneModel extends Backbone.Model
      storeName: '/samePlace'
    class AnotherModel extends Backbone.Model
      storeName: '/samePlace'
    saved = $.Deferred()
    model = new OneModel
    model.save 'paper', 'oragami', errorStatus: 0, success: ->
      saved.resolve()
    saved.done ->
      fetchedLocally = $.Deferred()
      model = new AnotherModel id: model.id
      model.fetch errorStatus: 0, success: ->
        fetchedLocally.resolve()
      fetchedLocally.done ->
        expect(model.get('paper')).to.equal 'oragami'
        done()

  describe 'Model.url', ->
    it 'is used as the store name, lacking anything below', (done) ->
      class OneModel extends Backbone.Model
        url: '/someplace'
      class AnotherModel extends Backbone.Model
        url: '/anotherPlace'
      saved = $.Deferred()
      model = new OneModel
      model.save 'paper', 'oragami', errorStatus: 0, success: ->
        saved.resolve()
      saved.done ->
        model = new AnotherModel id: model.id
        model.fetch errorStatus: 0, error: ->
          done()

  describe 'Model.urlRoot', ->
    it 'is used as the store name, lacking anything below', (done) ->
      class OneModel extends Backbone.Model
        url: '/samePlace'
        urlRoot: '/onePlace'
      class AnotherModel extends Backbone.Model
        url: '/samePlace'
        urlRoot: '/anotherPlce'
      saved = $.Deferred()
      model = new OneModel
      model.save 'paper', 'oragami', errorStatus: 0, success: ->
        saved.resolve()
      saved.done ->
        model = new AnotherModel id: model.id
        model.fetch errorStatus: 0, error: ->
          done()

  describe 'Collection.url', ->
    it 'is used as the store name, lacking anything below', (done) ->
      class MatchingCollection extends Backbone.Collection
        model: Model
        url: 'things/'
      class DisconnectedCollection extends Backbone.Collection
        model: Model
        url: 'does_not_match_the_model/'
      saved = $.Deferred()
      model = new Model
      model.save 'paper', 'oragami', errorStatus: 0, success: ->
        saved.resolve()
      saved.done ->
        collection = new MatchingCollection
        collection.fetch errorStatus: 0, success: ->
          expect(collection.size()).to.eql 1
          otherCollection = new DisconnectedCollection
          otherCollection.fetch errorStatus: 0, error: ->
            done()

  describe 'Model.storeName', ->
    it 'is used as the store name, lacking anything below', (done) ->
      class OneModel extends Backbone.Model
        urlRoot: 'commonURL/'
        storeName: 'someName'
      class AnotherModel extends Backbone.Model
        urlRoot: 'commonURL/'
        storeName: 'anotherName'
      saved = $.Deferred()
      model = new OneModel
      model.save 'paper', 'oragami', errorStatus: 0, success: ->
        saved.resolve()
      saved.done ->
        model = new AnotherModel id: model.id
        model.fetch errorStatus: 0, error: ->
          done()

  describe 'Collection.storeName', ->
    it 'is used as the store name if given', (done) ->
      class MatchingCollection extends Backbone.Collection
        model: Model
        url: 'commonURL/'
        storeName: 'things/'
      class DisconnectedCollection extends Backbone.Collection
        model: Model
        url: 'commonURL/'
        storeName: 'does_not_match_the_model/'
      saved = $.Deferred()
      model = new Model
      model.save 'paper', 'oragami', errorStatus: 0, success: ->
        saved.resolve()
      saved.done ->
        collection = new MatchingCollection
        fetchedMatching = $.Deferred()
        collection.fetch errorStatus: 0, success: -> fetchedMatching.resolve()
        fetchedMatching.done ->
          expect(collection.size()).to.eql 1
          collection = new DisconnectedCollection
          collection.fetch errorStatus: 0, error: ->
            done()
