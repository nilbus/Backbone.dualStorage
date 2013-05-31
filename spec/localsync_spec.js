(function() {
  describe('localsync', function() {
    describe('standard Backbone.sync methods', function() {
      describe('creating records', function() {
        it('creates records', function() {
          var create, model, ready, _ref;
          _ref = {}, ready = _ref.ready, create = _ref.create, model = _ref.model;
          runs(function() {
            create = spyOn(window.Store.prototype, 'create');
            model = {
              id: 1
            };
            return window.localsync('create', model, {
              success: (function() {
                return ready = true;
              }),
              error: (function() {
                return ready = true;
              })
            });
          });
          waitsFor((function() {
            return ready;
          }), "A callback should have been called", 100);
          return runs(function() {
            return expect(create).toHaveBeenCalledWith(model);
          });
        });
        it('does not overwrite existing models with fetch(add: true) unless passed merge: true', function() {
          var create, ready, _ref;
          _ref = {}, ready = _ref.ready, create = _ref.create;
          runs(function() {
            ready = false;
            create = spyOn(window.Store.prototype, 'find').andReturn({
              id: 1
            });
            create = spyOn(window.Store.prototype, 'create');
            return window.localsync('create', {
              id: 1
            }, {
              success: (function() {
                return ready = true;
              }),
              error: (function() {
                return ready = true;
              }),
              add: true
            });
          });
          waitsFor((function() {
            return ready;
          }), "A callback should have been called", 100);
          runs(function() {
            ready = false;
            expect(create).not.toHaveBeenCalled();
            return window.localsync('create', {
              id: 1
            }, {
              success: (function() {
                return ready = true;
              }),
              error: (function() {
                return ready = true;
              }),
              add: true,
              merge: true
            });
          });
          waitsFor((function() {
            return ready;
          }), "A callback should have been called", 100);
          return runs(function() {
            return expect(create).toHaveBeenCalled();
          });
        });
        return it('supports marking a new record dirty', function() {
          var create, dirty, model, ready, _ref;
          _ref = {}, ready = _ref.ready, create = _ref.create, model = _ref.model, dirty = _ref.dirty;
          runs(function() {
            model = {
              id: 1
            };
            create = spyOn(window.Store.prototype, 'create').andReturn(model);
            dirty = spyOn(window.Store.prototype, 'dirty');
            return window.localsync('create', model, {
              success: (function() {
                return ready = true;
              }),
              error: (function() {
                return ready = true;
              }),
              dirty: true
            });
          });
          waitsFor((function() {
            return ready;
          }), "A callback should have been called", 100);
          return runs(function() {
            expect(create).toHaveBeenCalledWith(model);
            return expect(dirty).toHaveBeenCalledWith(model);
          });
        });
      });
      describe('reading records', function() {
        it('reads models', function() {
          var find, model, ready, _ref;
          _ref = {}, ready = _ref.ready, find = _ref.find, model = _ref.model;
          runs(function() {
            find = spyOn(window.Store.prototype, 'find');
            model = new window.Backbone.Model({
              id: 1
            });
            return window.localsync('read', model, {
              success: (function() {
                return ready = true;
              }),
              error: (function() {
                return ready = true;
              })
            });
          });
          waitsFor((function() {
            return ready;
          }), "A callback should have been called", 100);
          return runs(function() {
            return expect(find).toHaveBeenCalledWith(model);
          });
        });
        return it('reads collections', function() {
          var findAll, ready, _ref;
          _ref = {}, ready = _ref.ready, findAll = _ref.findAll;
          runs(function() {
            findAll = spyOn(window.Store.prototype, 'findAll');
            return window.localsync('read', new window.Backbone.Collection, {
              success: (function() {
                return ready = true;
              }),
              error: (function() {
                return ready = true;
              })
            });
          });
          waitsFor((function() {
            return ready;
          }), "A callback should have been called", 100);
          return runs(function() {
            return expect(findAll).toHaveBeenCalled();
          });
        });
      });
      describe('updating records', function() {
        it('updates records', function() {
          var model, ready, update, _ref;
          _ref = {}, ready = _ref.ready, update = _ref.update, model = _ref.model;
          runs(function() {
            update = spyOn(window.Store.prototype, 'update');
            model = {
              id: 1
            };
            return window.localsync('update', model, {
              success: (function() {
                return ready = true;
              }),
              error: (function() {
                return ready = true;
              })
            });
          });
          waitsFor((function() {
            return ready;
          }), "A callback should have been called", 100);
          return runs(function() {
            return expect(update).toHaveBeenCalledWith(model);
          });
        });
        return it('supports marking an updated record dirty', function() {
          var dirty, model, ready, update, _ref;
          _ref = {}, ready = _ref.ready, update = _ref.update, model = _ref.model, dirty = _ref.dirty;
          runs(function() {
            model = {
              id: 1
            };
            update = spyOn(window.Store.prototype, 'update');
            dirty = spyOn(window.Store.prototype, 'dirty');
            return window.localsync('update', model, {
              success: (function() {
                return ready = true;
              }),
              error: (function() {
                return ready = true;
              }),
              dirty: true
            });
          });
          waitsFor((function() {
            return ready;
          }), "A callback should have been called", 100);
          return runs(function() {
            expect(update).toHaveBeenCalledWith(model);
            return expect(dirty).toHaveBeenCalledWith(model);
          });
        });
      });
      return describe('deleting records', function() {
        it('deletes records', function() {
          var destroy, model, ready, _ref;
          _ref = {}, ready = _ref.ready, destroy = _ref.destroy, model = _ref.model;
          runs(function() {
            destroy = spyOn(window.Store.prototype, 'destroy');
            model = {
              id: 1
            };
            return window.localsync('delete', model, {
              success: (function() {
                return ready = true;
              }),
              error: (function() {
                return ready = true;
              })
            });
          });
          waitsFor((function() {
            return ready;
          }), "A callback should have been called", 100);
          return runs(function() {
            return expect(destroy).toHaveBeenCalledWith(model);
          });
        });
        return it('supports marking a dirty record destroyed', function() {
          var destroy, destroyed, model, ready, _ref;
          _ref = {}, ready = _ref.ready, destroy = _ref.destroy, destroyed = _ref.destroyed, model = _ref.model;
          runs(function() {
            model = {
              id: 1
            };
            destroy = spyOn(window.Store.prototype, 'destroy');
            destroyed = spyOn(window.Store.prototype, 'destroyed');
            return window.localsync('delete', model, {
              success: (function() {
                return ready = true;
              }),
              error: (function() {
                return ready = true;
              }),
              dirty: true
            });
          });
          waitsFor((function() {
            return ready;
          }), "A callback should have been called", 100);
          return runs(function() {
            expect(destroy).toHaveBeenCalledWith(model);
            return expect(destroyed).toHaveBeenCalledWith(model);
          });
        });
      });
    });
    describe('extra methods', function() {
      it('clears out all records from the store', function() {
        return runs(function() {
          var clear;
          clear = spyOn(window.Store.prototype, 'clear');
          return window.localsync('clear', {}, {
            success: (function() {
              var ready;
              return ready = true;
            }),
            error: (function() {
              var ready;
              return ready = true;
            })
          });
        });
      });
      return it('reports whether or not it hasDirtyOrDestroyed', function() {
        return runs(function() {
          var clear;
          clear = spyOn(window.Store.prototype, 'hasDirtyOrDestroyed');
          return window.localsync('hasDirtyOrDestroyed', {}, {
            success: (function() {
              var ready;
              return ready = true;
            }),
            error: (function() {
              var ready;
              return ready = true;
            })
          });
        });
      });
    });
    return describe('callbacks', function() {
      return it('ignores callbacks when the ignoreCallbacks option is set', function() {
        var callback, start, _ref;
        _ref = {
          start: new Date().getTime()
        }, start = _ref.start, callback = _ref.callback;
        runs(function() {
          callback = jasmine.createSpy('callback');
          return window.localsync('create', {
            id: 1
          }, {
            success: callback,
            error: callback,
            ignoreCallbacks: true
          });
        });
        waitsFor((function() {
          return new Date().getTime() - start > 5;
        }), "This test is broken", 100);
        runs(function() {
          start = false;
          expect(callback).not.toHaveBeenCalled();
          return window.localsync('create', {
            id: 1
          }, {
            success: callback,
            error: callback
          });
        });
        return waitsFor((function() {
          return callback.wasCalled;
        }), 'The callback should have been called', 100);
      });
    });
  });
}).call(this);
