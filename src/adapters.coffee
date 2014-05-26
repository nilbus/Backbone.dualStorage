# Async storage adapter classes.
Backbone.storageAdapters = {}

class Backbone.storageAdapters.LocalStorageAdapter
  # Reference implementation with LocalStorage.
  constructor: (name) ->
    @name = name || 'Backbone.dualStorage.LocalStorage'
    @store = localStorage

  initialize: ->
    $.Deferred().resolve()

  set: (key, value) ->
    @store.setItem key, JSON.stringify value
    $.Deferred().resolve value

  get: (key) ->
    $.Deferred().resolve JSON.parse @store.getItem key

  remove: (key) ->
    @store.removeItem key
    $.Deferred().resolve()

  clear: ->
    @store.clear()
    $.Deferred().resolve()


class Backbone.storageAdapters.LawnchairStorageAdapter
  constructor: (name) ->
    @name = name || 'Backbone.dualStorage.Lawnchair'

  initialize: ->
    promise = $.Deferred()
    @store = new Lawnchair
      name: @name
      adapter: ['indexed-db'], -> promise.resolve()
    return promise

  set: (key, value) ->
    promise = $.Deferred()
    @store.save {key: key, value: value}, (data) -> promise.resolve data.value
    return promise

  get: (key) ->
    promise = $.Deferred()
    @store.get key, (data) -> promise.resolve data?.value
    return promise

  remove: (key) ->
    promise = $.Deferred()
    @store.remove key, -> promise.resolve()
    return promise

  clear: ->
    promise = $.Deferred()
    @store.nuke -> promise.resolve()
    return promise


# IndexedDB store is currently not working with Sticky.
class Backbone.storageAdapters.StickyStorageAdapter
  constructor: (name) ->
    @name = name || 'Backbone.dualStorage.Sticky'

  initialize: ->
    promise = $.Deferred()
    @store = new StickyStore
      name: @name
      adapters: ['indexedDB']
      ready: -> promise.resolve()
    return promise

  set: (key, value) ->
    promise = $.Deferred()
    @store.set {key: key, value: value}, (data) -> promise.resolve data.value
    return promise

  get: (key) ->
    promise = $.Deferred()
    @store.get key, (data) -> promise.resolve data?.value
    return promise

  remove: (key) ->
    promise = $.Deferred()
    @store.remove key, -> promise.resolve()
    return promise

  clear: ->
    promise = $.Deferred()
    @store.removeAll -> promise.resolve()
    return promise
