{backboneSync, localSync, dualSync, localStorage} = window
{Collection, Model} = {}

describe 'mode overrides', ->
  @timeout 100

  beforeEach ->
    localStorage.clear()
    class Model extends Backbone.Model
      idAttribute: '_id'
      urlRoot: 'things/'
    class Collection extends Backbone.Collection
      model: Model
      url: Model::urlRoot

  describe 'via properties', ->
    describe 'Model.local', ->
      it 'uses only local storage when true', (done) ->
        class LocalModel extends Model
          local: true
        model = new LocalModel
        backboneSync.reset()
        saved = $.Deferred()
        model.save null, success: -> saved.resolve()
        saved.done ->
          expect(backboneSync.callCount).to.equal 0
          done()

      it 'does not mark local changes dirty and will not sync them (deprecated; will sync after 2.0)', (done) ->
        class LocalModel extends Model
          local: true
        model = new LocalModel
        collection = new Collection [model]
        backboneSync.reset()
        saved = $.Deferred()
        model.save null, success: -> saved.resolve()
        saved.done ->
          expect(backboneSync.callCount).to.equal 0
          collection.syncDirtyAndDestroyed()
          expect(backboneSync.callCount).to.equal 0
          done()

    describe 'Model.remote', ->
      it 'uses only remote storage when true', (done) ->
        class RemoteModel extends Model
          remote: true
        model = new RemoteModel _id: 1
        backboneSync.reset()
        saved = $.Deferred()
        model.save null, success: -> saved.resolve()
        saved.done ->
          expect(backboneSync.callCount).to.equal 1
          model.fetch errorStatus: 0, error: -> done()

    describe 'Collection.local', ->
      it 'uses only local storage when true', (done) ->
        class LocalCollection extends Collection
          local: true
        collection = new LocalCollection
        backboneSync.reset()
        fetched = $.Deferred()
        collection.fetch success: -> fetched.resolve()
        fetched.done ->
          expect(backboneSync.callCount).to.equal 0
          done()

    describe 'Collection.remote', ->
      it 'uses only remote storage when true', (done) ->
        class RemoteCollection extends Collection
          remote: true
        collection = new RemoteCollection _id: 1
        backboneSync.reset()
        fetched = $.Deferred()
        collection.fetch success: -> fetched.resolve()
        fetched.done ->
          expect(backboneSync.callCount).to.equal 1
          collection.fetch errorStatus: 0, error: -> done()

  describe 'via methods, dynamically', ->
    describe 'Model.local', ->
      it 'uses only local storage when the function returns true', (done) ->
        class LocalModel extends Model
          local: -> true
        model = new LocalModel
        backboneSync.reset()
        saved = $.Deferred()
        model.save null, success: -> saved.resolve()
        saved.done ->
          expect(backboneSync.callCount).to.equal 0
          done()

    describe 'Model.remote', ->
      it 'uses only remote storage when the function returns true', (done) ->
        class RemoteModel extends Model
          remote: -> true
        model = new RemoteModel _id: 1
        backboneSync.reset()
        saved = $.Deferred()
        model.save null, success: -> saved.resolve()
        saved.done ->
          expect(backboneSync.callCount).to.equal 1
          model.fetch errorStatus: 0, error: -> done()

    describe 'Collection.local', ->
      it 'uses only local storage when the function returns true', (done) ->
        class LocalCollection extends Collection
          local: -> true
        collection = new LocalCollection
        backboneSync.reset()
        fetched = $.Deferred()
        collection.fetch success: -> fetched.resolve()
        fetched.done ->
          expect(backboneSync.callCount).to.equal 0
          done()

    describe 'Collection.remote', ->
      it 'uses only remote storage when the function returns true', (done) ->
        class RemoteCollection extends Collection
          remote: -> true
        collection = new RemoteCollection _id: 1
        backboneSync.reset()
        fetched = $.Deferred()
        collection.fetch success: -> fetched.resolve()
        fetched.done ->
          expect(backboneSync.callCount).to.equal 1
          collection.fetch errorStatus: 0, error: -> done()

  describe 'via options', ->
    describe '{remote: false}', ->
      it 'uses local storage as if offline', (done) ->
        model = new Model
        backboneSync.reset()
        saved = $.Deferred()
        model.save null, remote: false, success: -> saved.resolve()
        saved.done ->
          expect(backboneSync.callCount).to.equal 0
          done()

      it 'marks records dirty, to be synced when online', (done) ->
        model = new Model
        collection = new Collection [model]
        backboneSync.reset()
        saved = $.Deferred()
        model.save null, remote: false, success: -> saved.resolve()
        saved.done ->
          expect(backboneSync.callCount).to.equal 0
          collection.syncDirtyAndDestroyed()
          expect(backboneSync.callCount).to.equal 1
          done()
