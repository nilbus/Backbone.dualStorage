# Async storage adapters classes.

$ = Backbone.$ or window.$

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
    @initialize = _.memoize @initialize
    @name = name || 'Backbone.dualStorage'

  initialize: ->
    deferred = $.Deferred()
    @store = new StickyStore
      name: @name
      adapters: ['indexedDB', 'webSQL', 'localStorage']
      ready: -> deferred.resolve()
    deferred.promise()

  setItem: (key, value) ->
    @initialize().then =>
      deferred = $.Deferred()
      @store.set key, value, (storedValue) ->
        deferred.resolve storedValue
      deferred.promise()

  getItem: (key) ->
    @initialize().then =>
      deferred = $.Deferred()
      @store.get key, (storedValue) ->
        deferred.resolve storedValue
      deferred.promise()

  removeItem: (key) ->
    @initialize().then =>
      deferred = $.Deferred()
      @store.remove key, -> deferred.resolve()
      deferred.promise()


Backbone.storageAdapters =
  LocalStorageAdapter: LocalStorageAdapter
  StickyStorageAdapter: StickyStorageAdapter
