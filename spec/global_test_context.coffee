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
  Backbone: require('backbone')
  localStorage: localStorageMock()
  console:
    log: (args...) -> # console.log(args...)
  _: require('underscore')
window.Backbone.sync = jasmine.createSpy('sync').andCallFake (method, model, options) -> options.success(model)
window.window = window
exports.window = window
