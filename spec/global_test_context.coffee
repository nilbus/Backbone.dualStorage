localStorageMock = ->
  localStorage = {values: {}}
  localStorage.setItem = (key, val) ->
    this.values[key] = "#{val}"
  localStorage.getItem = (key) ->
    this.values[key]
  localStorage.removeItem = (key) ->
    delete this.values[key]
  localStorage.clear = ->
    this.values = {}
  Object.defineProperty localStorage.values, "length",
    get: ->
      Object.keys(this).length
  return localStorage

window =
  Backbone:
    Collection:
      prototype: {}
    sync: ->
  localStorage: localStorageMock()
  console:
    log: ->
  _: require('underscore')
window.window = window
exports.window = window
