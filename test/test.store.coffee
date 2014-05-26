describe 'Store', ->
  for storageName, storageClass of Backbone.storageAdapters
    do (storageName, storageClass) ->

      _describe = if storageClass is StickyStorage then describe.skip else describe
      _describe "with #{storageName}", ->
        {storage} = {}

        beforeEach (done) ->
          storage = new storageClass
          storage.initialize().done ->
            done()

        afterEach (done) ->
          storage.clear().done ->
            done()

        it 'takes a name and a storage adapter in its constructor', ->
          store = new Backbone.Store 'Store', storage

        it 'initializes correctly', (done) ->
          store = new Backbone.Store 'Store', storage
          expect(store.data).to.deep.eql {}
          store.initialize().done ->
            expect(store.data.dirty).to.eql []
            expect(store.data.destroyed).to.eql []
            expect(store.data.local).to.eql []
            expect(store.data.records).to.eql []
            expect(store.data.recordsById).to.eql {}
            done()

        {model, otherModel, store} = {}
        storeSetup = (done) ->
          model = new Backbone.Model
            id: 1
            abc: 123
          otherModel = new Backbone.Model
            id: 2
            xxx: 666
          store = new Backbone.Store 'Store', storage
          store.initialize().done -> done()

        storeClear = (done) ->
          store.clear().done -> done()

        describe 'when adding', ->
          beforeEach storeSetup
          afterEach storeClear

          it 'adds one model to the store', (done) ->
            store.add(model).done (saved) ->
              storage.get('Store').done (storeData) ->
                expect(storeData).to.deep.eql store.data
                expect(saved.attributes).to.deep.eql model.attributes
                expect(saved.attributes).to.deep.eql storeData.recordsById[1]
                expect(store.data).to.deep.eql
                    records: [1]
                    recordsById: 1: model.attributes
                    local: []
                    dirty: []
                    destroyed: []
                done()

          it 'adds many models to the store', (done) ->
            models = [model, otherModel]
            store.add(models).done (saved) ->
              storage.get('Store').done (storeData) ->
                expect(storeData).to.deep.eql store.data
                expect(saved[0].attributes).to.deep.eql model.attributes
                expect(saved[0].attributes).to.deep.eql storeData.recordsById[1]
                expect(saved[1].attributes).to.deep.eql otherModel.attributes
                expect(saved[1].attributes).to.deep.eql storeData.recordsById[2]
                expect(store.data).to.deep.eql
                    records: [1, 2]
                    recordsById:
                      1: model.attributes
                      2: otherModel.attributes
                    local: []
                    dirty: []
                    destroyed: []
                done()

          it 'adds the model creating a unique id using idAttribute', (done) ->
            model = new Backbone.Model
              abc: 123
            model.idAttribute = '_id'
            store.add(model).done (saved) ->
              storage.get('Store').done (storeData) ->
                expectedAttr = abc: 123, _id: model.id
                expect(storeData).to.deep.eql store.data
                expect(saved.attributes).to.deep.eql expectedAttr
                expect(saved.attributes).to.deep.eql storeData.recordsById[model.id]
                expect(saved.id).to.equal model.id
                recordsById = {}
                recordsById[model.id] = model.attributes
                expect(store.data).to.deep.eql
                    records: [model.id]
                    recordsById: recordsById
                    local: [model.id]
                    dirty: []
                    destroyed: []
                done()

          it 'throws an error if the model is already in the store', (done) ->
            store.add(model).done (saved) ->
              expect(-> store.add(model)).to.throw(/already in the store/)
              done()

        describe 'when updating', ->
          beforeEach storeSetup
          afterEach storeClear

          it 'updates the model in the store', (done) ->
            store.add(model).done ->
              model.set abc: 666
              store.update(model).done (updated) ->
                storage.get('Store').done (storeData) ->
                  expect(storeData).to.deep.eql store.data
                  expect(updated.attributes).to.deep.eql model.attributes
                  expect(updated.attributes).to.deep.eql storeData.recordsById[1]
                  expect(store.data).to.deep.eql
                    records: [1]
                    recordsById: {1: model.attributes}
                    local: []
                    dirty: []
                    destroyed: []
                  done()

          it 'throws an error if the model does not have an id', ->
            model = new Backbone.Model
            expect(-> store.update(model)).to.throw(/model does not have an id/)

          it 'throws an error if the model is not in the store', ->
            expect(-> store.update(model)).to.throw(/is not in the store/)

        describe 'when removing', ->
          beforeEach storeSetup
          afterEach storeClear

          it 'removes the model from the store', (done) ->
            store.add(model).done ->
              store.remove(model).done (removed) ->
                storage.get('Store').done (storeData) ->
                  expect(storeData).to.deep.eql store.data
                  expect(removed.attributes).to.deep.eql model.attributes
                  expect(store.data).to.deep.eql
                    records: []
                    recordsById: {}
                    local: []
                    dirty: []
                    destroyed: []
                  done()

          it 'removes a local model from the store', (done) ->
            model = new Backbone.Model
            store.add(model).done ->
              store.remove(model).done () ->
                storage.get('Store').done (storeData) ->
                  expect(storeData).to.deep.eql store.data
                  expect(store.data).to.deep.eql
                    records: []
                    recordsById: {}
                    local: []
                    dirty: []
                    destroyed: []
                  done()

          it 'removes the model from the dirty list', (done) ->
            store.add(model).done ->
              store.isDirty(model, true).done ->
                store.remove(model).done () ->
                  storage.get('Store').done (storeData) ->
                    expect(storeData).to.deep.eql store.data
                    expect(store.data).to.deep.eql
                      records: []
                      recordsById: {}
                      local: []
                      dirty: []
                      destroyed: []
                    done()

          it 'clears the store removing all saved data', (done) ->
            store.add(model).done ->
              store.isDirty(model, true).done ->
                store.isDestroyed(otherModel, true).done ->
                  store.clear().done ->
                    storage.get('Store').done (storeData) ->
                      expect(storeData).to.deep.eql {}
                      expect(store.data).to.deep.eql {}
                      done()

        describe 'when searching', ->
          beforeEach storeSetup
          afterEach storeClear

          it 'finds a model', (done) ->
            store.add(model).done ->
              expect(store.find 1).to.deep.eql model.attributes
              done()

          it 'finds all models', (done) ->
            store.add(model).done ->
              store.add(otherModel).done ->
                models = [model.attributes, otherModel.attributes]
                expect(store.find()).to.deep.eql models
                done()

          it 'finds all dirty models', (done) ->
            store.add(model).done ->
              store.isDirty(model, true).done ->
                expect(store.findDirty()).to.deep.eql [model.attributes]
                done()

          it 'finds all destroyed models', (done) ->
            store.isDestroyed(model, true).done ->
              expect(store.findDestroyed()).to.deep.eql [model.id]
              done()

          it 'returns correct values when model is not found', ->
            expect(store.find 1).to.be.undefined
            expect(store.findDirty 1).to.be.undefined
            expect(store.findDestroyed 1).to.be.false

        describe 'dirty / destroyed flags', (done) ->
          beforeEach storeSetup
          afterEach storeClear

          it 'marks a model as dirty', (done) ->
            store.add(model).done ->
              store.isDirty(model, true).done (dirtyModel) ->
                storage.get('Store').done (storeData) ->
                  expect(storeData).to.deep.eql store.data
                  expect(dirtyModel.attributes).to.deep.eql model.attributes
                  expect(store.data).to.deep.eql
                    records: [1]
                    recordsById: {1: model.attributes}
                    local: []
                    dirty: [1]
                    destroyed: []
                  done()

          it 'marks a model as destroyed', (done) ->
            store.isDestroyed(model, true).done (destroyedModel) ->
              storage.get('Store').done (storeData) ->
                expect(storeData).to.deep.eql store.data
                expect(destroyedModel.attributes).to.deep.eql model.attributes
                expect(store.data).to.deep.eql
                  records: []
                  recordsById: {}
                  local: []
                  dirty: []
                  destroyed: [1]
                done()

          it 'unmarks a model as dirty', (done) ->
            store.add(model).done ->
              store.isDirty(model, true).done () ->
                store.isDirty(model, false).done (dirtyModel) ->
                  storage.get('Store').done (storeData) ->
                    expect(storeData).to.deep.eql store.data
                    expect(dirtyModel.attributes).to.deep.eql model.attributes
                    expect(store.data).to.deep.eql
                      records: [1]
                      recordsById: {1: model.attributes}
                      local: []
                      dirty: []
                      destroyed: []
                    done()

          it 'unmarks a model as destroyed', (done) ->
            store.isDestroyed(model, true).done () ->
              store.isDestroyed(model, false).done (dirtyModel) ->
                storage.get('Store').done (storeData) ->
                  expect(storeData).to.deep.eql store.data
                  expect(dirtyModel.attributes).to.deep.eql model.attributes
                  expect(store.data).to.deep.eql
                    records: []
                    recordsById: {}
                    local: []
                    dirty: []
                    destroyed: []
                  done()

          it 'reports correctly if there are dirty models', (done) ->
            store.add(model).done ->
              store.isDirty(model, true).done ->
                expect(store.hasDirtyOrDestroyed).to.be.ok
                done()

          it 'reports correctly if there are destroyed models', (done) ->
            store.isDestroyed(model, true).done ->
              expect(store.hasDirtyOrDestroyed).to.be.ok
              done()

          it 'throws an error if the model is not in the store', ->
            expect(-> store.isDirty(model, true)).to.throw(/is not in the store/)

          it 'throws an error if trying to mark a stored model as destroyed', (done) ->
            store.add(model).done ->
              expect(-> store.isDestroyed(model, true)).to.throw(/is still in the store/)
              done()
