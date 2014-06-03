// Generated by CoffeeScript 1.7.1
(function() {
  describe("Ensures that parse is invoked concistently", function() {
    var Collection, Model;
    Model = Backbone.Model.extend({
      url: "tests",
      defaults: function() {
        return {
          name: void 0,
          subCollection: new Backbone.Collection
        };
      },
      toJSON: function() {
        var attributes;
        attributes = Backbone.Model.prototype.toJSON.apply(this);
        attributes.subCollection = this.get("subCollection").toJSON();
        return attributes;
      },
      parse: function(response) {
        var parsed;
        parsed = _.clone(response);
        parsed.subCollection = new Backbone.Collection(response.subCollection || []);
        return parsed;
      }
    });
    Collection = Backbone.Collection.extend({
      model: Model,
      url: "tests"
    });
    beforeEach(function() {
      return localStorage.clear;
    });
    describe("Fetching a single model", function() {
      return it("parses the server response with the models parse method before storing it in the localStorage", function() {
        var localResponse, model, parseSpy, serverResponse;
        model = new Model({
          id: 1
        });
        serverResponse = {
          Model: {
            id: 1,
            name: "test"
          }
        };
        localResponse = {
          id: 1,
          name: "Test"
        };
        parseSpy = spyOn(model, "parse").andReturn(localResponse);
        model.fetch({
          serverResponse: serverResponse
        });
        expect(model.get("name")).toBe("Test");
        return expect(parseSpy).toHaveBeenCalledWith(serverResponse);
      });
    });
    describe("Fetching a collection", function() {
      return it("first pases the server response to the parse method of the collection", function() {
        var collection, localResponse, model, modelParseSpy, parseSpy, serverResponse;
        collection = new Collection();
        model = new Model({
          id: 1,
          name: "OldName"
        });
        collection.add(model);
        serverResponse = {
          Models: [
            {
              Model: {
                id: 1,
                name: "Test"
              },
              Model: {
                id: 2,
                name: "Other"
              }
            }
          ]
        };
        localResponse = [
          {
            id: 1,
            name: "Test"
          }, {
            id: 2,
            name: "Other"
          }
        ];
        parseSpy = spyOn(collection, "parse").andReturn(localResponse);
        modelParseSpy = spyOn(Model.prototype, "parse").andCallThrough();
        collection.fetch({
          serverResponse: serverResponse
        });
        expect(parseSpy).toHaveBeenCalledWith(serverResponse, jasmine.any(Object));
        expect(modelParseSpy.argsForCall[0][0]).toEqual({
          id: 1,
          name: "Test"
        });
        expect(modelParseSpy.argsForCall[1][0]).toEqual({
          id: 2,
          name: "Other"
        });
        expect(modelParseSpy.argsForCall[2][0]).toEqual({
          id: 1,
          name: "Test"
        });
        expect(modelParseSpy.argsForCall[3][0]).toEqual({
          id: 2,
          name: "Other"
        });
        expect(collection.length).toBe(2);
        expect(collection.get(1).get("name")).toBe("Test");
        return expect(collection.get(2).get("name")).toBe("Other");
      });
    });
    describe("Creating a model instance", function() {
      return it("the server response should be parsed with parse", function() {
        var localResponse, model, parseSpy, serverResponse;
        model = new Model({
          name: "Old name"
        });
        serverResponse = {
          Model: {
            id: 1,
            name: "test"
          }
        };
        localResponse = {
          id: 1,
          name: "Test"
        };
        parseSpy = spyOn(model, "parse").andReturn(localResponse);
        model.save({}, {
          serverResponse: serverResponse
        });
        expect(parseSpy).toHaveBeenCalledWith(serverResponse);
        return expect(model.get("name")).toBe("Test");
      });
    });
    describe("Updating a model instance", function() {
      return it("the updated result from the server should be parsed using model.parse to adopt the format", function() {
        var localResponse, model, parseSpy, serverResponse;
        model = new Model({
          id: 1,
          name: "Old name"
        });
        serverResponse = {
          Model: {
            id: 1,
            name: "test"
          }
        };
        localResponse = {
          id: 1,
          name: "Test"
        };
        parseSpy = spyOn(model, "parse").andReturn(localResponse);
        model.save({}, {
          serverResponse: serverResponse
        });
        expect(parseSpy).toHaveBeenCalledWith(serverResponse);
        return expect(model.get("name")).toBe("Test");
      });
    });
    describe("Updating a model instance with a temporary id", function() {
      return it("should parse the result from the server", function() {
        var localResponse, model, parseSpy, serverResponse;
        model = new Model({
          name: "Old name"
        });
        model.save({}, {
          remote: false
        });
        serverResponse = {
          Model: {
            id: 1,
            name: "test"
          }
        };
        localResponse = {
          id: 1,
          name: "Test"
        };
        parseSpy = spyOn(model, "parse").andReturn(localResponse);
        model.save({}, {
          serverResponse: serverResponse
        });
        expect(parseSpy).toHaveBeenCalledWith(serverResponse);
        return expect(model.get("name")).toBe("Test");
      });
    });
    return describe("Parse local fetched entities", function() {
      return describe("Create new entry", function() {
        return it("should pass the model as json instead of it's attributes to parse", function() {
          var model, parseSpy;
          model = new Model({
            name: "Old name"
          });
          parseSpy = spyOn(model, "parse").andCallThrough();
          model.save({}, {
            remote: false
          });
          expect(parseSpy.argsForCall[0][0]).not.toBeUndefined();
          expect(parseSpy.argsForCall[0][0].subCollection).not.toBeUndefined();
          expect(parseSpy.argsForCall[0][0].subCollection).toEqual([]);
          expect(model.id).not.toBeUndefined();
          return expect(model.get("name")).toBe("Old name");
        });
      });
    });
  });

}).call(this);

//# sourceMappingURL=parse_specs.map
