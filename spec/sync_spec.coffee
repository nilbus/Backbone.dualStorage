{backboneSync, localSync, dualSync, localStorage} = window
{Collection, Model} = {}

describe 'syncing offline changes when there are dirty or destroyed records', ->
  @timeout 100

  beforeEach ->
    localStorage.clear()
    class Model extends Backbone.Model
      idAttribute: '_id'
      urlRoot: 'things/'
    class Collection extends Backbone.Collection
      model: Model
      url: Model::urlRoot

  beforeEach (done) ->
    # Save two models in a collection while online.
    # Then while offline, modify one, and delete the other
    @collection = new Collection [
      {_id: 1, name: 'change me'},
      {_id: 2, name: 'delete me'}
    ]
    allSaved = @collection.map (model) ->
      saved = $.Deferred()
      model.save null, success: ->
        saved.resolve()
      saved
    allModified = $.when(allSaved...).then =>
      dirtied = $.Deferred()
      @collection.get(1).save 'name', 'dirty me', errorStatus: 0, success: ->
        dirtied.resolve()
      destroyed = $.Deferred()
      @collection.get(2).destroy errorStatus: 0, success: ->
        destroyed.resolve()
      $.when dirtied, destroyed
    allModified.done ->
      done()

  describe 'Model.fetch', ->
    it 'reads models in dirty collections from local storage until a successful sync', (done) ->
      fetched = $.Deferred()
      model = new Model _id: 1
      model.fetch serverResponse: {_id: 1, name: 'this response is never used'}, success: ->
        fetched.resolve()
      fetched.done ->
        expect(model.get('name')).to.equal 'dirty me'
        done()

  describe 'Collection.fetch', ->
    it 'excludes destroyed models when working locally before a sync', (done) ->
      fetched = $.Deferred()
      collection = new Collection
      collection.fetch serverResponse: [{_id: 3, name: 'this response is never used'}], success: ->
        fetched.resolve()
      fetched.done ->
        expect(collection.size()).to.equal 1
        expect(collection.first().get('name')).to.equal 'dirty me'
        done()

  describe 'Collection.dirtyModels', ->
    it 'returns an array of models that have been created or updated while offline', (done) ->
      @collection.dirtyModels().then (dirtyModels) =>
        expect(dirtyModels).to.eql [@collection.get(1)]
        done()

  describe 'Collection.destroyedModelIds', ->
    it 'returns an array of ids for models that have been destroyed while offline', (done) ->
      @collection.destroyedModelIds().then (destroyedModelIds) =>
        expect(destroyedModelIds).to.eql ['2']
        done()

  describe 'Collection.syncDirty', ->
    it 'attempts to save online all records that were created/updated while offline', (done) ->
      backboneSync.reset()
      @collection.syncDirty().then =>
        expect(backboneSync.callCount).to.equal 1
        @collection.dirtyModels().then (dirtyModels) ->
          expect(dirtyModels).to.eql []
          done()

  describe 'Collection.syncDestroyed', ->
    it 'attempts to destroy online all records that were destroyed while offline', (done) ->
      backboneSync.reset()
      @collection.syncDestroyed().then =>
        expect(backboneSync.callCount).to.equal 1
        @collection.destroyedModelIds().then (destroyedModelIds) ->
          expect(destroyedModelIds).to.eql []
          done()

  describe 'Collection.syncDirtyAndDestroyed', ->
    it 'attempts to sync online all records that were modified while offline', (done) ->
      backboneSync.reset()
      @collection.syncDirtyAndDestroyed().then =>
        expect(backboneSync.callCount).to.equal 2
        @collection.dirtyModels().then (dirtyModels) =>
          expect(dirtyModels).to.eql []
          @collection.destroyedModelIds().then (destroyedModelIds) =>
            expect(destroyedModelIds).to.eql []
            done()

  describe 'Model.destroy', ->
    it 'does not mark models for deletion that were created and destroyed offline', (done) ->
      model = new Model name: 'transient'
      @collection.add model
      model.save null, errorStatus: 0
      destroyed = $.Deferred()
      model.destroy errorStatus: 0, success: -> destroyed.resolve()
      destroyed.done =>
        backboneSync.reset()
        @collection.syncDestroyed()
        expect(backboneSync.callCount).to.equal 1
        expect(backboneSync.firstCall.args[1].id).not.to.equal model.id
        done()

  describe 'Model.id', ->
    it 'for new records with a temporary id is replaced by the id returned by the server', (done) ->
      saved = $.Deferred()
      model = new Model
      @collection.add model
      model.save 'name', 'created while offline', errorStatus: 0, success: ->
        saved.resolve()
      saved.done =>
        expect(model.id.length).to.equal 36
        backboneSync.reset()
        @collection.syncDirty()
        expect(backboneSync.callCount).to.equal 2
        expect(backboneSync.lastCall.args[0]).to.equal 'create'
        expect(backboneSync.lastCall.args[1].id).to.be.null
        expect(backboneSync.lastCall.args[1].get('_id')).to.be.null
        done()
