window =
  Backbone:
    Collection:
      prototype: {}
    sync: ->
  localStorage:
    getItem: ->
    setItem: ->
    removeItem: ->
  console:
    log: ->
  _: require('underscore')
window.window = window
exports.window = window
