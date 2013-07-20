{Throttle, Backbone, localStorage} = window
beforeEach -> Throttle.reset()

describe 'monkey patching', ->
  it 'aliases Backbone.sync to backboneSync', ->
    expect(window.backboneSync).toBeDefined()
    expect(window.backboneSync.identity).toEqual('sync')

describe 'offline localStorage sync', ->
  {collection, throttler} = {}
  beforeEach ->
    throttler = spyOn(Throttle, 'run').andCallFake (name, task) -> task(->)
    localStorage.clear()
    localStorage.setItem 'cats', '2,3,a'
    localStorage.setItem 'cats_dirty', '2,a'
    localStorage.setItem 'cats_destroyed', '3'
    localStorage.setItem 'cats3', '{"id": "2", "color": "auburn"}'
    localStorage.setItem 'cats3', '{"id": "3", "color": "burgundy"}'
    localStorage.setItem 'cats3', '{"id": "a", "color": "scarlet"}'
    collection = new Backbone.Collection [
      {id: 2, color: 'auburn'},
      {id: 3, color: 'burgundy'},
      {id: 'a', color: 'burgundy'}
    ]
    collection.url = -> 'cats'

  describe 'syncDirtyAndDestroyed', ->
    it 'calls syncDirty and syncDestroyed', ->
      syncDirty = spyOn(Backbone.Collection.prototype, 'syncDirty')
      syncDestroyed = spyOn(Backbone.Collection.prototype, 'syncDestroyed')
      collection.syncDirtyAndDestroyed()
      expect(syncDirty).toHaveBeenCalled()
      expect(syncDestroyed).toHaveBeenCalled()

  describe 'syncDirty', ->
    it 'finds and saves all dirty models', ->
      saveInteger = spyOn(collection.get(2), 'save').andCallThrough()
      saveString = spyOn(collection.get('a'), 'save').andCallThrough()
      collection.syncDirty()
      expect(saveInteger).toHaveBeenCalled()
      expect(saveString).toHaveBeenCalled()
      expect(localStorage.getItem 'cats_dirty').toBeFalsy()

  describe 'syncDestroyed', ->
    it 'finds all models marked as destroyed and destroys them', ->
      destroy = spyOn collection.get(3), 'destroy'
      collection.syncDestroyed()
      expect(localStorage.getItem 'cats_destroyed').toBeFalsy()

  describe 'multiple calls to syncDirty or syncDestroyed before the save completes', ->
    it 'does not produce multiple calls to save, to prevent duplicate create/update requests', ->
      collection.syncDirtyAndDestroyed()
      expect(throttler.calls.length).toEqual 2

describe 'Throttle.run', ->
  it 'runs jobs immediately unless there is already one running', ->
    ran1 = ran2 = false
    Throttle.run -> ran1 = true
    Throttle.run -> ran2 = true
    expect(ran1).toBeTruthy()
    expect(ran2).toBeFalsy()

  it 'accets a job name as an optional first parameter', ->
    ran1 = ran2 = ran3 = ran4 = false
    Throttle.run 'job', -> ran1 = true
    Throttle.run 'job', -> ran2 = true
    Throttle.run 'another', -> ran3 = true
    Throttle.run 'another', -> ran4 = true
    expect(ran1).toBeTruthy()
    expect(ran2).toBeFalsy()
    expect(ran3).toBeTruthy()
    expect(ran4).toBeFalsy()

  it 'sends a callback argument to the throttled function that starts the next job when called', ->
    ran1 = ran2 = false
    callback = null
    Throttle.run (runWhenDone) ->
      ran1 = true
      callback = runWhenDone
    Throttle.run -> ran2 = true
    expect(ran1).toBeTruthy()
    expect(ran2).toBeFalsy()
    callback()
    expect(ran2).toBeTruthy()

  it 'replaces an existing queued job when a new job is queued', ->
    ran1 = ran2 = ran3 = false
    callback = null
    Throttle.run (runWhenDone) ->
      ran1 = true
      callback = runWhenDone
    Throttle.run -> ran2 = true
    Throttle.run -> ran3 = true
    expect(ran1).toBeTruthy()
    expect(ran2).toBeFalsy()
    expect(ran3).toBeFalsy()
    callback()
    expect(ran2).toBeFalsy()
    expect(ran3).toBeTruthy()

  it 'is done when it executes all of its jobs, but it still accepts further jobs', ->
    ran1 = ran2 = ran3 = false
    callback = null
    Throttle.run (runWhenDone) ->
      ran1 = true
      callback = runWhenDone
    Throttle.run (runWhenDone) ->
      ran2 = true
      callback = runWhenDone
    Throttle.run -> ran2 = true
    expect(ran1).toBeTruthy()
    expect(ran2).toBeFalsy()
    callback()
    expect(ran2).toBeTruthy()
    callback()
    Throttle.run -> ran3 = true
    expect(ran3).toBeTruthy()
