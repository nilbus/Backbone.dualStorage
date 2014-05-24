# Async storage adapters classes.

$ = Backbone.$

class LocalStorageAdapter
  # Simple implementation with LocalStorage for reference.
  initialize: ->
    $.Deferred().resolve().promise()

  setItem: (key, value) ->
    localStorage.setItem key, value
    $.Deferred().resolve(value).promise()

  getItem: (key) ->
    $.Deferred().resolve(localStorage.getItem(key)).promise()

  removeItem: (key) ->
    localStorage.removeItem key
    $.Deferred().resolve().promise()


class StickyStorageAdapter
  constructor: (name) ->
    @name = name || 'Backbone.dualStorage'

  initialize: ->
    deferred = $.Deferred()
    @store = new StickyStore
      name: @name
      adapters: ['indexedDB', 'webSQL', 'localStorage']
      ready: -> deferred.resolve()
    return deferred.promise()

  setItem: (key, value) ->
    deferred = $.Deferred()
    @store.set key, value, (storedValue) ->
      deferred.resolve storedValue
    return deferred.promise()

  getItem: (key) ->
    deferred = $.Deferred()
    @store.get key, (storedValue) ->
      deferred.resolve storedValue
    return deferred.promise()

  removeItem: (key) ->
    deferred = $.Deferred()
    @store.remove key, -> deferred.resolve()
    return deferred.promise()


Backbone.storageAdapters =
  LocalStorageAdapter: LocalStorageAdapter
  StickyStorageAdapter: StickyStorageAdapter
