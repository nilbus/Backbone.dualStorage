{backboneSync, localSync, dualSync, localStorage} = window
{Collection, Model} = {}

describe 'Backbone.dualStorage', ->
  @timeout 10

  beforeEach ->
    backboneSync.calls = []
    localStorage.clear()
    class Model extends Backbone.Model
      idAttribute: '_id'
      urlRoot: 'things/'
    class Collection extends Backbone.Collection
      model: Model
      url: Model::urlRoot

  describe 'basic persistence', ->
    describe 'online operations cached for offline use', ->
      describe 'Model.fetch', ->
        it 'stores the result locally after fetch', (done) ->
          fetchedOnline = $.Deferred()
          model = new Model _id: 1
          model.fetch serverResponse: {_id: 1, pants: 'fancy'}, success: ->
            fetchedOnline.resolve()
          fetchedOnline.done ->
            fetchedLocally = $.Deferred()
            model = new Model _id: 1
            model.fetch remote: false, success: ->
              fetchedLocally.resolve()
            fetchedLocally.done ->
              expect(model.get('pants')).to.equal 'fancy'
              done()

        it 'replaces previously fetched data in local storage when fetched again', (done) ->
          fetch1 = $.Deferred()
          model = new Model _id: 1
          model.fetch serverResponse: {_id: 1, pants: 'fancy'}, success: ->
            fetch1.resolve()
          fetch1.done ->
            fetch2 = $.Deferred()
            model = new Model _id: 1
            model.fetch serverResponse: {_id: 1, shoes: 'boots'}, success: ->
              fetch2.resolve()
            fetch2.done ->
              fetchedLocally = $.Deferred()
              model = new Model _id: 1
              model.fetch remote: false, success: ->
                fetchedLocally.resolve()
              fetchedLocally.done ->
                expect(model.get('pants')).to.be.falsy
                expect(model.get('shoes')).to.equal 'boots'
                done()

      describe 'Model.save', ->
        describe 'creating a new model', ->
          it 'stores saved attributes locally', (done) ->
            saved = $.Deferred()
            model = new Model
            model.save 'paper', 'oragami', serverResponse: {_id: 1, paper: 'oragami'}, success: ->
              saved.resolve()
            saved.done ->
              fetchedLocally = $.Deferred()
              model = new Model _id: 1
              model.fetch remote: false, success: ->
                fetchedLocally.resolve()
              fetchedLocally.done ->
                expect(model.get('paper')).to.equal 'oragami'
                done()

          it 'updates the model with changes in the server response', (done) ->
            saved = $.Deferred()
            model = new Model role: 'admin', action: 'escalating privileges'
            response =        role: 'peon',  action: 'escalating privileges', _id: 1, updated_at: '2014-07-04 00:00:00'
            model.save null, serverResponse: response, success: ->
              saved.resolve()
            saved.done ->
              fetchedLocally = $.Deferred()
              model = new Model _id: 1
              model.fetch remote: false, success: ->
                fetchedLocally.resolve()
              fetchedLocally.done ->
                expect(model.attributes).to.eql response
                done()

        describe 'updating an existing model', ->
          it 'stores saved attributes locally', (done) ->
            saved = $.Deferred()
            model = new Model _id: 1
            model.save 'paper', 'oragami', success: ->
              saved.resolve()
            saved.done ->
              fetchedLocally = $.Deferred()
              model = new Model _id: 1
              model.fetch remote: false, success: ->
                fetchedLocally.resolve()
              fetchedLocally.done ->
                expect(model.get('paper')).to.equal 'oragami'
                done()

          it 'updates the model with changes in the server response', (done) ->
            saved = $.Deferred()
            model = new Model _id: 1, role: 'admin', action: 'escalating privileges'
            response =        _id: 1, role: 'peon',  action: 'escalating privileges', updated_at: '2014-07-04 00:00:00'
            model.save null, serverResponse: response, success: ->
              saved.resolve()
            saved.done ->
              fetchedLocally = $.Deferred()
              model = new Model _id: 1
              model.fetch remote: false, success: ->
                fetchedLocally.resolve()
              fetchedLocally.done ->
                expect(model.attributes).to.eql response
                done()

          it 'replaces previously saved attributes when saved again', (done) ->
            saved1 = $.Deferred()
            model = new Model _id: 1
            model.save 'paper', 'hats', success: ->
              saved1.resolve()
            saved1.done ->
              saved2 = $.Deferred()
              model = new Model _id: 1
              model.save 'leather', 'belts', success: ->
                saved2.resolve()
              saved2.done ->
                fetchedLocally = $.Deferred()
                model = new Model _id: 1
                model.fetch remote: false, success: ->
                  fetchedLocally.resolve()
                fetchedLocally.done ->
                  expect(model.get('paper')).to.be.falsy
                  expect(model.get('leather')).to.equal 'belts'
                  done()

      describe 'Collection.destroy', ->
        it 'removes the locally stored version', (done) ->
          saved = $.Deferred()
          model = new Model _id: 1
          model.save null, success: ->
            saved.resolve()
          saved.done ->
            destroyed = $.Deferred()
            model = new Model _id: 1
            model.destroy success: ->
              destroyed.resolve()
            destroyed.done ->
              fetchedLocally = $.Deferred()
              model = new Model _id: 1
              model.fetch remote: false, error: -> done()

        it "doesn't error if there was no locally stored version", (done) ->
          destroyed = $.Deferred()
          model = new Model _id: 1
          model.destroy success: -> done()

      describe 'Collection.fetch', ->
        it 'stores each model locally', (done) ->
          fetched = $.Deferred()
          response_collection = [
            {_id: 1, hair: 'strawberry'},
            {_id: 2, hair: 'burgundy'}
          ]
          collection = new Collection
          collection.fetch serverResponse: response_collection, success: ->
            fetched.resolve()
          fetched.done ->
            expect(collection.length).to.equal 2
            fetchedLocally = $.Deferred()
            collection = new Collection
            collection.fetch remote: false, success: ->
              fetchedLocally.resolve()
            fetchedLocally.done ->
              expect(collection.length).to.equal 2
              expect(collection.map (model) -> model.id).to.eql [1,2]
              expect(collection.get(2).get('hair')).to.equal 'burgundy'
              done()

        it 'replaces the existing local collection', (done) ->
          saved = $.Deferred()
          model = new Model _id: 3, hair: 'chocolate'
          model.save null, success: ->
            saved.resolve()
          saved.done ->
            fetched = $.Deferred()
            response_collection = [
              {_id: 1, hair: 'strawberry'},
              {_id: 2, hair: 'burgundy'}
            ]
            collection = new Collection
            collection.fetch serverResponse: response_collection, success: ->
              fetched.resolve()
            fetched.done ->
              fetchedLocally = $.Deferred()
              collection = new Collection
              collection.fetch remote: false, success: ->
                fetchedLocally.resolve()
              fetchedLocally.done ->
              expect(collection.length).to.equal 2
              expect(collection.map (model) -> model.id).to.eql [1,2]
              done()

        describe 'options: {add: true}', ->
          it 'adds to the existing local collection', (done) ->
            saved = $.Deferred()
            model = new Model _id: 3, hair: 'chocolate'
            model.save null, success: ->
              saved.resolve()
            saved.done ->
              fetched = $.Deferred()
              response_collection = [
                {_id: 1, hair: 'strawberry'},
                {_id: 2, hair: 'burgundy'}
              ]
              collection = new Collection
              collection.fetch add: true, serverResponse: response_collection, success: ->
                fetched.resolve()
              fetched.done ->
                fetchedLocally = $.Deferred()
                collection = new Collection
                collection.fetch remote: false, success: ->
                  fetchedLocally.resolve()
                fetchedLocally.done ->
                  expect(collection.length).to.equal 3
                  expect(collection.map (model) -> model.id).to.include.members [1,2,3]
                  done()

          describe 'options: {add: true, merge: false}', ->
            it '(FAILS; DISABLED) does not update attributes on existing local models', (done) ->
              return done()
              saved = $.Deferred()
              model = new Model _id: 3, hair: 'chocolate'
              model.save null, success: ->
                saved.resolve()
              saved.done ->
                fetched = $.Deferred()
                response_collection = [
                  {_id: 1, hair: 'strawberry'},
                  {_id: 2, hair: 'burgundy'},
                  {_id: 3, hair: 'white chocolate'}
                ]
                collection = new Collection
                collection.fetch add: true, merge: false, serverResponse: response_collection, success: ->
                  fetched.resolve()
                fetched.done ->
                  fetchedLocally = $.Deferred()
                  collection = new Collection
                  collection.fetch remote: false, success: ->
                    fetchedLocally.resolve()
                  fetchedLocally.done ->
                    expect(collection.length).to.equal 3
                    expect(collection.get(3).get('hair')).to.equal 'chocolate'
                    done()
