window = require('./spec_helper').window

describe 'window.Store', ->
  describe 'creation', ->
    it 'takes a name in its constructor', ->
      store = new window.Store 'convenience store'
      expect(store.name).toBe 'convenience store'

  describe 'persistence', ->
    {store, model} = {}
    beforeEach ->
      window.localStorage.clear()
      window.localStorage.setItem 'cats', '3'
      window.localStorage.setItem 'cats3', '{"id": "3", "color": "burgundy"}'
      store = new window.Store 'cats'

    it 'fetches records by id with find', ->
      expect(store.find(id: 3)).toEqual id: '3', color: 'burgundy'

    it 'fetches all records with findAll', ->
      expect(store.findAll()).toEqual [id: '3', color: 'burgundy']

    it 'clears out its records', ->
      store.clear()
      expect(window.localStorage.getItem 'cats').toBe ''
      expect(window.localStorage.getItem 'cats3').toBeUndefined()

    it 'creates records', ->
      model = id: 2, color: 'blue'
      store.create model
      expect(window.localStorage.getItem 'cats').toBe '3,2'
      expect(JSON.parse(window.localStorage.getItem 'cats2')).toEqual id: 2, color: 'blue'

    it 'generates an id when creating records with no id', ->
      window.localStorage.clear()
      store = new window.Store 'cats'
      model = color: 'calico', idAttribute: 'id', set: (attribute, value) -> this[attribute] = value
      store.create model
      expect(model.id).not.toBeUndefined()
      expect(window.localStorage.getItem('cats')).toBe model.id

    it 'updates records', ->
      store.update id: 3, color: 'green'
      expect(JSON.parse(window.localStorage.getItem 'cats3')).toEqual id: 3, color: 'green'

    it 'destroys records', ->
      store.destroy id: 3
      expect(window.localStorage.getItem 'cats').toBe ''
      expect(window.localStorage.getItem 'cats3').toBeUndefined()

  describe 'offline', ->
    xit 'marks records dirty and clean', ->
    xit 'marks records destroyed', ->
    xit 'reports if it hasDirtyOrDestroyed records', ->
