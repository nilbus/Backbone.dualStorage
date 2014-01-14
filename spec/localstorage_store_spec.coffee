{Store, localStorage} = window

describe 'window.Store', ->
  {store, model} = {}
  beforeEach ->
    localStorage.clear()
    localStorage.setItem 'cats', '3'
    localStorage.setItem 'cats3', '{"id": "3", "color": "burgundy"}'
    store = new Store 'cats'
    store.initialize()
    return store

  describe 'creation', ->
    it 'takes a name in its constructor', ->
      store = new Store 'convenience store'
      expect(store.name).toBe 'convenience store'

  describe 'persistence', ->
    describe 'find', ->
      it 'fetches records by id', ->
        store.find(id: 3).done (result) ->
          expect(result).toEqual id: '3', color: 'burgundy'

      # JSON.parse(null) causes error on Android 2.x devices, so it should be avoided
      it 'does not try to JSON.parse null values', ->
        spyOn JSON, 'parse'
        store.find(id: 'unpersistedId').done ->
          expect(JSON.parse).not.toHaveBeenCalledWith(null)

      it 'returns null when not found', ->
        store.find(id: 'unpersistedId').done (result) ->
          expect(result).toBeNull()

    it 'fetches all records with findAll', ->
      store.findAll().done (result) ->
        expect(result).toEqual [id: '3', color: 'burgundy']

    it 'clears out its records', ->
      store.clear().done ->
        expect(localStorage.getItem 'cats').toBe ''
        expect(localStorage.getItem 'cats3').toBeNull()

    it 'creates records', ->
      model = id: 2, color: 'blue'
      store.create(model).done ->
        expect(localStorage.getItem 'cats').toBe '3,2'
        expect(JSON.parse(localStorage.getItem 'cats2')).toEqual id: 2, color: 'blue'

    it 'overwrites existing records with the same id on create', ->
      model = id: 3, color: 'lavender'
      store.create(model).done ->
        expect(JSON.parse(localStorage.getItem 'cats3')).toEqual id: 3, color: 'lavender'

    it 'generates an id when creating records with no id', ->
      localStorage.clear()
      store = new Store 'cats'
      model = color: 'calico', idAttribute: 'id', set: (attribute, value) -> this[attribute] = value
      store.create(model).done ->
        expect(model.id).not.toBeNull()
        expect(localStorage.getItem('cats')).toBe model.id

    it 'updates records', ->
      store.update(id: 3, color: 'green').done ->
        expect(JSON.parse(localStorage.getItem 'cats3')).toEqual id: 3, color: 'green'

    it 'destroys records', ->
      store.destroy(id: 3).done ->
        expect(localStorage.getItem 'cats').toBe ''
        expect(localStorage.getItem 'cats3').toBeNull()

  describe 'offline', ->
    it 'on a clean slate, hasDirtyOrDestroyed returns false', ->
      store.hasDirtyOrDestroyed().done (result) ->
        expect(result).toBeFalsy()

    it 'marks records dirty and clean, and reports if it hasDirtyOrDestroyed records', ->
      store.dirty(id: 3).done ->
        store.hasDirtyOrDestroyed().done (result) ->
          expect(result).toBeTruthy()
          store.clean(id: 3, 'dirty').done ->
            store.hasDirtyOrDestroyed().done (result) ->
              expect(result).toBeFalsy()

    it 'marks records destroyed and clean from destruction, and reports if it hasDirtyOrDestroyed records', ->
      store.destroyed(id: 3).done ->
        store.hasDirtyOrDestroyed().done (result) ->
          expect(result).toBeTruthy()
          store.clean(id: 3, 'destroyed').done ->
            store.hasDirtyOrDestroyed().done (result) ->
              expect(result).toBeFalsy()

    it 'cleans the list of dirty or destroyed models out of localStorage after saving or destroying', ->
      collection = new Backbone.Collection [{id: 2, color: 'auburn'}, {id: 3, color: 'burgundy'}]
      collection.url = 'cats'
      store.dirty(id: 2).done ->
        store.destroyed(id: 3).done ->
          store.hasDirtyOrDestroyed().done (result) ->
            expect(result).toBeTruthy()
            collection.get(2).save().done ->
              collection.get(3).destroy().done ->
                store.hasDirtyOrDestroyed().done (result) ->
                  expect(result).toBeFalsy()
                  expect(localStorage.getItem('cats_dirty').length).toBe 0
                  expect(localStorage.getItem('cats_destroyed').length).toBe 0
