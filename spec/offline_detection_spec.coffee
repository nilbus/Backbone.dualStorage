{backboneSync, localSync, dualSync, localStorage} = window
{Collection, Model} = {}

describe 'offline detection', ->
  @timeout 100

  beforeEach ->
    localStorage.clear()
    class Model extends Backbone.Model
      idAttribute: '_id'
      urlRoot: 'things/'
    class Collection extends Backbone.Collection
      model: Model
      url: Model::urlRoot

  describe 'Backbone.DualStorage.offlineStatusCodes', ->
    beforeEach -> @originalOfflineStatusCodes = Backbone.DualStorage.offlineStatusCodes
    afterEach -> Backbone.DualStorage.offlineStatusCodes = @originalOfflineStatusCodes

    describe 'as an array property', ->
      it 'acts as offline when a server response code is in included in the array', (done) ->
        Backbone.DualStorage.offlineStatusCodes = [500, 502]
        model = new Model _id: 1
        saved = $.Deferred()
        model.save 'name', 'original name saved locally', success: -> saved.resolve()
        saved.done ->
          model = new Model _id: 1
          fetchedLocally = $.Deferred()
          response = 'response ignored because of the "offline" status code'
          model.fetch errorStatus: 500, serverResponse: {name: response}, success: ->
            fetchedLocally.resolve()
          fetchedLocally.done ->
            expect(model.get('name')).to.equal 'original name saved locally'
            done()

      it 'defaults to [408, 502] (Request Timeout, Bad Gateway)', ->
        expect(Backbone.DualStorage.offlineStatusCodes).to.eql [408, 502]

    describe 'as an array returned by a method', ->
      it 'acts as offline when a server response code is in included in the array', (done) ->
        serverReportsToBeOffline = (xhr) ->
          if xhr?.response?['error_message'] == 'Offline for maintenance'
            [200]
          else
            []
        Backbone.DualStorage.offlineStatusCodes = serverReportsToBeOffline
        model = new Model _id: 1
        saved = $.Deferred()
        model.save 'name', 'original name saved locally', success: -> saved.resolve()
        saved.done ->
          model = new Model _id: 1
          fetchedLocally = $.Deferred()
          model.fetch serverResponse: {_id: 1, name: 'unknown', error_message: 'Offline for maintenance'}, success: ->
            fetchedLocally.resolve()
          fetchedLocally.done ->
            expect(model.get('name')).to.equal 'original name saved locally'
            done()

    it 'treats an ajax response status code 0 as offline, regardless of offlineStatusCodes', (done) ->
      model = new Model _id: 1
      saved = $.Deferred()
      model.save 'name', 'original name saved locally', success: -> saved.resolve()
      saved.done ->
        model = new Model _id: 1
        fetchedLocally = $.Deferred()
        response = 'response ignored because of the "offline" status code'
        model.fetch errorStatus: 0, serverResponse: {name: response}, success: ->
          fetchedLocally.resolve()
        fetchedLocally.done ->
          expect(model.get('name')).to.equal 'original name saved locally'
          done()
