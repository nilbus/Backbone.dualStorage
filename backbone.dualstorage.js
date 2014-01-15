// Generated by CoffeeScript 1.6.3
/*
Backbone dualStorage Adapter v1.1.0

A simple module to replace `Backbone.sync` with *localStorage*-based
persistence. Models are given GUIDS, and saved into a JSON object. Simple
as that.
*/


(function() {
  var LocalStorageAdapter, S4, backboneSync, callbackTranslator, dualSync, localSync, modelUpdatedWithResponse, onlineSync, parseRemoteResponse, result,
    __slice = [].slice;

  LocalStorageAdapter = (function() {
    function LocalStorageAdapter() {}

    LocalStorageAdapter.prototype.initialize = function() {
      return $.Deferred().resolve;
    };

    LocalStorageAdapter.prototype.setItem = function(key, value) {
      localStorage.setItem(key, value);
      return $.Deferred().resolve(value);
    };

    LocalStorageAdapter.prototype.getItem = function(key) {
      return $.Deferred().resolve(localStorage.getItem(key));
    };

    LocalStorageAdapter.prototype.removeItem = function(key) {
      localStorage.removeItem(key);
      return $.Deferred().resolve();
    };

    return LocalStorageAdapter;

  })();

  Backbone.storageAdapter = new LocalStorageAdapter;

  Backbone.storageAdapter.initialize();

  Backbone.Collection.prototype.syncDirty = function() {
    var storeName,
      _this = this;
    storeName = result(this, 'storeName') || result(this, 'url');
    return Backbone.storageAdapter.getItem("" + storeName + "_dirty").then(function(store) {
      var id, ids, model, models;
      ids = (store && store.split(',')) || [];
      models = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = ids.length; _i < _len; _i++) {
          id = ids[_i];
          _results.push(id.length === 36 ? this.findWhere({
            id: id
          }) : this.get(id));
        }
        return _results;
      }).call(_this);
      return $.when.apply($, (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = models.length; _i < _len; _i++) {
          model = models[_i];
          if (model) {
            _results.push(model.save());
          }
        }
        return _results;
      })());
    });
  };

  Backbone.Collection.prototype.syncDestroyed = function() {
    var storeName,
      _this = this;
    storeName = result(this, 'storeName') || result(this, 'url');
    return Backbone.storageAdapter.getItem("" + storeName + "_destroyed").then(function(store) {
      var id, ids, model, models, _i, _len;
      ids = (store && store.split(',')) || [];
      models = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = ids.length; _i < _len; _i++) {
          id = ids[_i];
          _results.push(new this.model({
            id: id
          }));
        }
        return _results;
      }).call(_this);
      for (_i = 0, _len = models.length; _i < _len; _i++) {
        model = models[_i];
        model.collection = _this;
      }
      return $.when.apply($, (function() {
        var _j, _len1, _results;
        _results = [];
        for (_j = 0, _len1 = models.length; _j < _len1; _j++) {
          model = models[_j];
          _results.push(model.destroy());
        }
        return _results;
      })());
    });
  };

  Backbone.Collection.prototype.syncDirtyAndDestroyed = function() {
    var _this = this;
    return this.syncDirty().then(function() {
      return _this.syncDestroyed();
    });
  };

  S4 = function() {
    return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
  };

  window.Store = (function() {
    Store.prototype.sep = '';

    function Store(name) {
      this.name = name;
      this.dirtyName = "" + name + "_dirty";
      this.destroyedName = "" + name + "_destroyed";
      this.records = [];
    }

    Store.prototype.initialize = function() {
      var _this = this;
      return this.recordsOn(this.name).done(function(result) {
        return _this.records = result || [];
      });
    };

    Store.prototype.generateId = function() {
      return S4() + S4() + '-' + S4() + '-' + S4() + '-' + S4() + '-' + S4() + S4() + S4();
    };

    Store.prototype.save = function() {
      return Backbone.storageAdapter.setItem(this.name, this.records.join(','));
    };

    Store.prototype.recordsOn = function(key) {
      return Backbone.storageAdapter.getItem(key).then(function(store) {
        return (store && store.split(',')) || [];
      });
    };

    Store.prototype.dirty = function(model) {
      var _this = this;
      return this.recordsOn(this.dirtyName).then(function(dirtyRecords) {
        if (!_.include(dirtyRecords, model.id.toString())) {
          dirtyRecords.push(model.id.toString());
          return Backbone.storageAdapter.setItem(_this.dirtyName, dirtyRecords.join(',')).then(function() {
            return model;
          });
        }
        return model;
      });
    };

    Store.prototype.clean = function(model, from) {
      var store,
        _this = this;
      store = "" + this.name + "_" + from;
      return this.recordsOn(store).then(function(dirtyRecords) {
        if (_.include(dirtyRecords, model.id.toString())) {
          return Backbone.storageAdapter.setItem(store, _.without(dirtyRecords, model.id.toString()).join(',')).then(function() {
            return model;
          });
        }
        return model;
      });
    };

    Store.prototype.destroyed = function(model) {
      var _this = this;
      return this.recordsOn(this.destroyedName).then(function(destroyedRecords) {
        if (!_.include(destroyedRecords, model.id.toString())) {
          destroyedRecords.push(model.id.toString());
          Backbone.storageAdapter.setItem(_this.destroyedName, destroyedRecords.join(',')).then(function() {
            return model;
          });
        }
        return model;
      });
    };

    Store.prototype.create = function(model) {
      var _this = this;
      if (!_.isObject(model)) {
        return $.Deferred().resolve(model);
      }
      if (!model.id) {
        model.id = this.generateId();
        model.set(model.idAttribute, model.id);
      }
      return Backbone.storageAdapter.setItem(this.name + this.sep + model.id, JSON.stringify(model)).then(function() {
        _this.records.push(model.id.toString());
        return _this.save().then(function() {
          return model;
        });
      });
    };

    Store.prototype.update = function(model) {
      var _this = this;
      return Backbone.storageAdapter.setItem(this.name + this.sep + model.id, JSON.stringify(model)).then(function() {
        if (!_.include(_this.records, model.id.toString())) {
          _this.records.push(model.id.toString());
        }
        return _this.save().then(function() {
          return model;
        });
      });
    };

    Store.prototype.clear = function() {
      var id,
        _this = this;
      return $.when.apply($, ((function() {
        var _i, _len, _ref, _results;
        _ref = this.records;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          id = _ref[_i];
          _results.push(Backbone.storageAdapter.removeItem(this.name + this.sep + id));
        }
        return _results;
      }).call(this))).then(function() {
        _this.records = [];
        return _this.save();
      });
    };

    Store.prototype.hasDirtyOrDestroyed = function() {
      var _this = this;
      return Backbone.storageAdapter.getItem(this.dirtyName).then(function(dirty) {
        return Backbone.storageAdapter.getItem(_this.destroyedName).then(function(destroyed) {
          return !_.isEmpty(dirty) || !_.isEmpty(destroyed);
        });
      });
    };

    Store.prototype.find = function(model) {
      return Backbone.storageAdapter.getItem(this.name + this.sep + model.id).then(function(modelAsJson) {
        if (modelAsJson === null) {
          return null;
        }
        return JSON.parse(modelAsJson);
      });
    };

    Store.prototype.findAll = function() {
      var id;
      return $.when.apply($, ((function() {
        var _i, _len, _ref, _results;
        _ref = this.records;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          id = _ref[_i];
          _results.push(Backbone.storageAdapter.getItem(this.name + this.sep + id));
        }
        return _results;
      }).call(this))).then(function() {
        var model, models, _i, _len, _results;
        models = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _results = [];
        for (_i = 0, _len = models.length; _i < _len; _i++) {
          model = models[_i];
          _results.push(JSON.parse(model));
        }
        return _results;
      });
    };

    Store.prototype.destroy = function(model) {
      var _this = this;
      return Backbone.storageAdapter.removeItem(this.name + this.sep + model.id).then(function() {
        _this.records = _.without(_this.records, model.id.toString());
        return _this.save().then(function() {
          return model;
        });
      });
    };

    return Store;

  })();

  callbackTranslator = {
    needsTranslation: Backbone.VERSION === '0.9.10',
    forBackboneCaller: function(callback) {
      if (this.needsTranslation) {
        return function(model, resp, options) {
          return callback.call(null, resp);
        };
      } else {
        return callback;
      }
    },
    forDualstorageCaller: function(callback, model, options) {
      if (this.needsTranslation) {
        return function(resp) {
          return callback.call(null, model, resp, options);
        };
      } else {
        return callback;
      }
    }
  };

  localSync = function(method, model, options) {
    var isValidModel, store,
      _this = this;
    isValidModel = (method === 'clear') || (method === 'hasDirtyOrDestroyed');
    isValidModel || (isValidModel = model instanceof Backbone.Model);
    isValidModel || (isValidModel = model instanceof Backbone.Collection);
    if (!isValidModel) {
      throw new Error('model parameter is required to be a backbone model or collection.');
    }
    store = new Store(options.storeName);
    return store.initialize().then(function() {
      var promise;
      promise = (function() {
        switch (method) {
          case 'read':
            if (model.id) {
              return store.find(model);
            } else {
              return store.findAll();
            }
            break;
          case 'hasDirtyOrDestroyed':
            return store.hasDirtyOrDestroyed();
          case 'clear':
            return store.clear();
          case 'create':
            return store.find(model).then(function(preExisting) {
              if (!(options.add && !options.merge && preExisting)) {
                return store.create(model).then(function(model) {
                  if (options.dirty) {
                    return store.dirty(model).then(function() {
                      return model;
                    });
                  }
                  return model;
                });
              } else {
                return preExisting;
              }
            });
          case 'update':
            return store.update(model).then(function(model) {
              if (options.dirty) {
                return store.dirty(model);
              } else {
                return store.clean(model, 'dirty');
              }
            });
          case 'delete':
            return store.destroy(model).then(function() {
              if (options.dirty) {
                return store.destroyed(model);
              } else {
                if (model.id.toString().length === 36) {
                  return store.clean(model, 'dirty');
                } else {
                  return store.clean(model, 'destroyed');
                }
              }
            });
        }
      })();
      return promise.then(function(response) {
        if (response != null ? response.attributes : void 0) {
          response = response.attributes;
        }
        if (!options.ignoreCallbacks) {
          if (response) {
            options.success(response);
          } else {
            options.error('Record not found');
          }
        }
        return response;
      });
    });
  };

  result = function(object, property) {
    var value;
    if (!object) {
      return null;
    }
    value = object[property];
    if (_.isFunction(value)) {
      return value.call(object);
    } else {
      return value;
    }
  };

  parseRemoteResponse = function(object, response) {
    if (!(object && object.parseBeforeLocalSave)) {
      return response;
    }
    if (_.isFunction(object.parseBeforeLocalSave)) {
      return object.parseBeforeLocalSave(response);
    }
  };

  modelUpdatedWithResponse = function(model, response) {
    var modelClone;
    modelClone = new Backbone.Model;
    modelClone.idAttribute = model.idAttribute;
    modelClone.set(model.attributes);
    modelClone.set(modelClone.parse(response));
    return modelClone;
  };

  backboneSync = Backbone.sync;

  onlineSync = function(method, model, options) {
    options.success = callbackTranslator.forBackboneCaller(options.success);
    options.error = callbackTranslator.forBackboneCaller(options.error);
    return backboneSync(method, model, options);
  };

  dualSync = function(method, model, options) {
    var error, local, success, temporaryId;
    options.storeName = result(model.collection, 'storeName') || result(model, 'storeName') || result(model.collection, 'url') || result(model, 'urlRoot') || result(model, 'url');
    options.success = callbackTranslator.forDualstorageCaller(options.success, model, options);
    options.error = callbackTranslator.forDualstorageCaller(options.error, model, options);
    if (result(model, 'remote') || result(model.collection, 'remote')) {
      return onlineSync(method, model, options);
    }
    local = result(model, 'local') || result(model.collection, 'local');
    options.dirty = options.remote === false && !local;
    if (options.remote === false || local) {
      return localSync(method, model, options);
    }
    options.ignoreCallbacks = true;
    success = options.success;
    error = options.error;
    switch (method) {
      case 'read':
        return localSync('hasDirtyOrDestroyed', model, options).then(function(hasDirtyOrDestroyed) {
          if (hasDirtyOrDestroyed) {
            return success(localSync(method, model, options));
          } else {
            options.success = function(resp, status, xhr) {
              var go;
              resp = parseRemoteResponse(model, resp);
              go = function() {
                var collection, idAttribute, m, modelAttributes, models, responseModel, _i, _len;
                if (_.isArray(resp)) {
                  collection = model;
                  idAttribute = collection.model.prototype.idAttribute;
                  models = [];
                  for (_i = 0, _len = resp.length; _i < _len; _i++) {
                    modelAttributes = resp[_i];
                    model = collection.get(modelAttributes[idAttribute]);
                    if (model) {
                      responseModel = modelUpdatedWithResponse(model, modelAttributes);
                    } else {
                      responseModel = new collection.model(modelAttributes);
                    }
                    models.push(responseModel);
                  }
                  return $.when.apply($, ((function() {
                    var _j, _len1, _results;
                    _results = [];
                    for (_j = 0, _len1 = models.length; _j < _len1; _j++) {
                      m = models[_j];
                      _results.push(localSync('create', m, options));
                    }
                    return _results;
                  })())).then(function() {
                    return success(resp, status, xhr);
                  });
                } else {
                  responseModel = modelUpdatedWithResponse(model, resp);
                  return localSync('create', responseModel, options).then(function() {
                    return success(resp, status, xhr);
                  });
                }
              };
              if (!options.add) {
                return localSync('clear', model, options).then(go);
              } else {
                return go();
              }
            };
            options.error = function(resp) {
              return localSync(method, model, options).then(function(result) {
                return success(result);
              });
            };
            return onlineSync(method, model, options);
          }
        });
      case 'create':
        options.success = function(resp, status, xhr) {
          var updatedModel;
          updatedModel = modelUpdatedWithResponse(model, resp);
          return localSync(method, updatedModel, options).then(function() {
            return success(resp, status, xhr);
          });
        };
        options.error = function(resp) {
          options.dirty = true;
          return localSync(method, model, options).then(function(result) {
            return success(result);
          });
        };
        return onlineSync(method, model, options);
      case 'update':
        if (_.isString(model.id) && model.id.length === 36) {
          temporaryId = model.id;
          options.success = function(resp, status, xhr) {
            var updatedModel;
            updatedModel = modelUpdatedWithResponse(model, resp);
            model.set(model.idAttribute, temporaryId, {
              silent: true
            });
            return localSync('delete', model, options).then(function() {
              return localSync('create', updatedModel, options).then(function() {
                return success(resp, status, xhr);
              });
            });
          };
          options.error = function(resp) {
            options.dirty = true;
            model.set(model.idAttribute, temporaryId, {
              silent: true
            });
            return localSync(method, model, options).then(function(result) {
              return success(result);
            });
          };
          model.set(model.idAttribute, null, {
            silent: true
          });
          return onlineSync('create', model, options);
        } else {
          options.success = function(resp, status, xhr) {
            var updatedModel;
            updatedModel = modelUpdatedWithResponse(model, resp);
            return localSync(method, updatedModel, options).then(function() {
              return success(resp, status, xhr);
            });
          };
          options.error = function(resp) {
            options.dirty = true;
            return localSync(method, model, options).then(function(result) {
              return success;
            });
          };
          return onlineSync(method, model, options);
        }
        break;
      case 'delete':
        if (_.isString(model.id) && model.id.length === 36) {
          return localSync(method, model, options);
        } else {
          options.success = function(resp, status, xhr) {
            return localSync(method, model, options).then(function() {
              return success(resp, status, xhr);
            });
          };
          options.error = function(resp) {
            options.dirty = true;
            return localSync(method, model, options).then(function(result) {
              return success(result);
            });
          };
          return onlineSync(method, model, options);
        }
    }
  };

  Backbone.sync = dualSync;

}).call(this);
