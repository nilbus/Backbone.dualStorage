{backboneSync, localSync, dualSync, localStorage} = window
{Collection, Model} = {}

describe 'pre-parsing', ->
  @timeout 100

  beforeEach ->
    localStorage.clear()
    class Model extends Backbone.Model
      idAttribute: '_id'
      urlRoot: 'things/'
    class Collection extends Backbone.Collection
      model: Model
      url: Model::urlRoot

  beforeEach ->
    Model::parse = (response) ->
      response.phrase = response.phrase?.replace /!/, ' parseWasHere'
      response
    Model::parseBeforeLocalSave = (unformattedReponse) ->
      _id: 1
      phrase: unformattedReponse
    Collection::parse = (response) ->
      i = 0
      for item in response
        _.extend item, order: i++
        item
    Collection::parseBeforeLocalSave = (response) ->
      _.map response, (item) ->
        _id: item

  describe 'Model.parseBeforeLocalSave', ->
    describe 'on fetch', ->
      it 'transforms the response into a hash of attributes with an id', (done) ->
        model = new Model
        fetched = $.Deferred()
        model.fetch serverResponse: 'Hi!!', success: -> fetched.resolve()
        fetched.done ->
          expect(model.id).to.equal 1
          expect(model.get('phrase')).not.to.be.null
          done()

  describe 'Model.parse', ->
    describe 'when used alongside parseBeforeLocalSave', ->
      it 'modifies attributes in the response to fit an API response to the backbone model', (done) ->
        model = new Model
        fetched = $.Deferred()
        model.fetch serverResponse: 'Hi!', success: -> fetched.resolve()
        fetched.done ->
          expect(model.get('phrase')).to.equal 'Hi parseWasHere'
          done()

      it 'bug: parse should not be called twice on the response'
        # model = new Model
        # fetched = $.Deferred()
        # model.fetch serverResponse: 'Hi!!', success: -> fetched.resolve()
        # fetched.done ->
        #   expect(model.get('phrase')).to.equal 'Hi parseWasHere!'
        #   done()

  describe 'Collection.parseBeforeLocalSave', ->
    describe 'on fetch', ->
      it 'transforms the response into an array of hash attributes with an id', (done) ->
        collection = new Collection
        fetched = $.Deferred()
        collection.fetch serverResponse: ['a', 'b'], success: -> fetched.resolve()
        fetched.done ->
          expect(collection.get('a')).not.to.be.null
          expect(collection.get('b')).not.to.be.null
          done()

  describe 'Collection.parse', ->
    describe 'when used alongside parseBeforeLocalSave', ->
      it 'modifies objects in the response to fit an API response to the backbone model', (done) ->
        collection = new Collection
        fetched = $.Deferred()
        collection.fetch serverResponse: ['a', 'b'], success: -> fetched.resolve()
        fetched.done ->
          expect(collection.get('a').get('order')).to.equal 0
          expect(collection.get('b').get('order')).to.equal 1
          done()
