# Async storage adapters classes.

class LocalStorageAdapter
  # Simple implementation with LocalStorage for reference.
  initialize: ->
    $.Deferred().resolve

  setItem: (key, value) ->
    localStorage.setItem key, value
    $.Deferred().resolve value

  getItem: (key) ->
    $.Deferred().resolve localStorage.getItem key

  removeItem: (key) ->
    localStorage.removeItem key
    $.Deferred().resolve()


class StickyStorageAdapter
  constructor: (name) ->
    @name = name || 'Backbone.dualStorage'

  initialize: ->
    promise = $.Deferred()
    @store = new StickyStore
      name: @name
      adapters: ['indexedDB', 'webSQL', 'localStorage']
      ready: -> promise.resolve()
    return promise

  setItem: (key, value) ->
    promise = $.Deferred()
    @store.set key, value, (storedValue) ->
      promise.resolve storedValue
    return promise

  getItem: (key) ->
    promise = $.Deferred()
    @store.get key, (storedValue) ->
      promise.resolve storedValue
    return promise

  removeItem: (key) ->
    promise = $.Deferred()
    @store.remove key, -> promise.resolve()
    return promise


Backbone.storageAdapters =
  LocalStorageAdapter: LocalStorageAdapter
  StickyStorageAdapter: StickyStorageAdapter
