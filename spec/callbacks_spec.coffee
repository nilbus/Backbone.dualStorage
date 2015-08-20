{backboneSync, localSync, dualSync, localStorage} = window
{Collection, Model} = {}

describe 'callbacks', ->
  @timeout 100

  beforeEach ->
    localStorage.clear()
    class Model extends Backbone.Model
      idAttribute: '_id'
      urlRoot: 'things/'
    class Collection extends Backbone.Collection
      model: Model
      url: Model::urlRoot

  describe 'when offline', ->
    describe 'with no local store initialized for the model/collection', ->
      beforeEach ->
        @model = new Model

      it 'calls the error callback', (done) ->
        @model.fetch errorStatus: 0, error: -> done()

      it 'fails the deferred promise', (done) ->
        @model.fetch(errorStatus: 0).fail -> done()

      it 'triggers the error event', (done) ->
        @model.on 'error', -> done()
        @model.fetch errorStatus: 0

    describe 'with a local store initialized', ->
      beforeEach (done) ->
        @model = new Model
        @model.save null, errorStatus: 0, success: -> done()

      it 'calls the success callback', (done) ->
        @model.fetch errorStatus: 0, success: -> done()

      it 'resolves the deferred promise', (done) ->
        @model.fetch().then -> done()

      it 'triggers the sync event', (done) ->
        @model.on 'sync', -> done()
        @model.fetch errorStatus: 0

    describe 'when fetching an id that is not cached', ->
      beforeEach (done) ->
        model = new Model _id: 1
        model.save null, errorStatus: 0, success: -> done()

      it 'calls the error callback', (done) ->
        model = new Model _id: 999
        model.fetch errorStatus: 0, error: -> done()

      it 'fails the deferred promise', (done) ->
        model = new Model _id: 999
        model.fetch(errorStatus: 0).fail -> done()

      it 'triggers the error event', (done) ->
        model = new Model _id: 999
        model.on 'error', -> done()
        model.fetch errorStatus: 0

    describe 'the dirty attribute', ->
      beforeEach (done) ->
        @model = new Model
        @model.save null, errorStatus: 0, success: -> done()

      it 'is set in the callback options', (done) ->
        @model.fetch errorStatus: 0, success: (model, reponse, options) ->
          expect(options.dirty).to.be.true
          done()

      it 'is set in the promise callback options', (done) ->
        @model.fetch(errorStatus: 0).then (model, reponse, options) ->
          expect(options.dirty).to.be.true
          done()

      it 'is set in the sync event options', (done) ->
        @model.on 'sync', (model, response, options) ->
          expect(options.dirty).to.be.true
          done()
        @model.fetch errorStatus: 0

  describe 'when online', ->
    describe 'receiving an error response', ->
      beforeEach ->
        @model = new Model

      it 'calls the error callback', (done) ->
        @model.fetch errorStatus: 500, error: -> done()

      it 'fails the deferred promise', (done) ->
        @model.fetch(errorStatus: 500).fail -> done()

      it 'triggers the error event', (done) ->
        @model.on 'error', -> done()
        @model.fetch errorStatus: 500

    describe 'receiving a successful response', ->
      beforeEach ->
        @model = new Model _id: 1

      it 'calls the success callback', (done) ->
        @model.fetch success: -> done()

      it 'resolves the deferred promise', (done) ->
        @model.fetch().then -> done()

      it 'triggers the sync event', (done) ->
        @model.on 'sync', -> done()
        @model.fetch()

    describe 'the dirty attribute', ->
      beforeEach (done) ->
        @model = new Model
        @model.save '_id', '1', success: -> done()

      it 'is set in the callback options', (done) ->
        @model.fetch success: (model, reponse, options) ->
          expect(options.dirty).not.to.be.true
          done()

      it 'is set in the promise callback options', (done) ->
        @model.fetch().then (model, reponse, options) ->
          expect(options.dirty).not.to.be.true
          done()

      it 'is set in the sync event options', (done) ->
        @model.on 'sync', (model, response, options) ->
          expect(options.dirty).not.to.be.true
          done()
        @model.fetch()
