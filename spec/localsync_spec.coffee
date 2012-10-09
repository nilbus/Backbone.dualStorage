window = require('./spec_helper').window

describe 'localsync', ->
  describe 'standard Backbone.sync methods', ->
    describe 'creating records', ->
      it 'creates records', ->
        create = spyOn(window.Store.prototype, 'create')
        model = id: 1
        window.localsync 'create', model, {success: (->), error: (->)}
        expect(create).toHaveBeenCalledWith model

      it 'does not overwrite existing models with fetch(add: true) unless passed merge: true', ->
        create = spyOn(window.Store.prototype, 'find').andReturn id: 1
        create = spyOn(window.Store.prototype, 'create')
        window.localsync 'create', {id: 1}, {success: (->), error: (->), add: true}
        expect(create).not.toHaveBeenCalled()
        window.localsync 'create', {id: 1}, {success: (->), error: (->), add: true, merge: true}
        expect(create).toHaveBeenCalled()

      it 'supports marking a new record dirty', ->
        model = id: 1
        create = spyOn(window.Store.prototype, 'create').andReturn model
        dirty = spyOn(window.Store.prototype, 'dirty')
        window.localsync 'create', model, {success: (->), error: (->), dirty: true}
        expect(create).toHaveBeenCalledWith model
        expect(dirty).toHaveBeenCalledWith model

    describe 'reading records', ->
      it 'reads models', ->
        find = spyOn(window.Store.prototype, 'find')
        model = new window.Backbone.Model id: 1
        window.localsync 'read', model, {success: (->), error: (->)}
        expect(find).toHaveBeenCalledWith model

      it 'reads collections', ->
        findAll = spyOn(window.Store.prototype, 'findAll')
        window.localsync 'read', new window.Backbone.Collection, {success: (->), error: (->)}
        expect(findAll).toHaveBeenCalled()

    describe 'updating records', ->
      it 'updates records', ->
        update = spyOn(window.Store.prototype, 'update')
        model = id: 1
        window.localsync 'update', model, {success: (->), error: (->)}
        expect(update).toHaveBeenCalledWith model

      it 'supports marking an updated record dirty', ->
        model = id: 1
        update = spyOn(window.Store.prototype, 'update')
        dirty = spyOn(window.Store.prototype, 'dirty')
        window.localsync 'update', model, {success: (->), error: (->), dirty: true}
        expect(update).toHaveBeenCalledWith model
        expect(dirty).toHaveBeenCalledWith model

    describe 'deleting records', ->
      it 'deletes records', ->
        destroy = spyOn(window.Store.prototype, 'destroy')
        model = id: 1
        window.localsync 'delete', model, {success: (->), error: (->)}
        expect(destroy).toHaveBeenCalledWith model

      it 'supports marking a dirty record destroyed', ->
        model = id: 1
        destroy = spyOn(window.Store.prototype, 'destroy')
        destroyed = spyOn(window.Store.prototype, 'destroyed')
        window.localsync 'delete', model, {success: (->), error: (->), dirty: true}
        expect(destroy).toHaveBeenCalledWith model
        expect(destroyed).toHaveBeenCalledWith model

  describe 'extra methods', ->
    it 'clears out all records from the store', ->
      clear = spyOn(window.Store.prototype, 'clear')
      window.localsync 'clear', {}, {success: (->), error: (->)}

    it 'reports whether or not it hasDirtyOrDestroyed', ->
      clear = spyOn(window.Store.prototype, 'hasDirtyOrDestroyed')
      window.localsync 'hasDirtyOrDestroyed', {}, {success: (->), error: (->)}


  describe 'callbacks', ->
    it 'ignores callbacks when the ignoreCallbacks option is set', ->
      callback = jasmine.createSpy 'callback'
      window.localsync 'create', {id: 1}, {success: callback, error: callback, ignoreCallbacks: true}
      expect(callback).not.toHaveBeenCalled()
      window.localsync 'create', {id: 1}, {success: callback, error: callback}
      expect(callback).toHaveBeenCalled()
