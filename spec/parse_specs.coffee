describe "Ensures that parse is invoked concistently", ->
  Model = Backbone.Model.extend {
    url: "tests",
    defaults: ->
      { name: undefined, subCollection: new Backbone.Collection }

    toJSON: ->
      attributes = Backbone.Model.prototype.toJSON.apply this
      attributes.subCollection = this.get("subCollection").toJSON()
      attributes

    parse: (response) ->
      parsed = _.clone(response)
      parsed.subCollection = new Backbone.Collection(response.subCollection || [])
      parsed
  }

  Collection = Backbone.Collection.extend {
    model: Model,
    url: "tests"
  }

  beforeEach ->
    localStorage.clear

  describe "Fetching a single model", ->
    it "parses the server response with the models parse method before storing it in the localStorage", ->
      model = new Model { id: 1 };

      serverResponse = { Model: { id: 1, name: "test" } }
      localResponse = { id: 1, name: "Test" }

      parseSpy = spyOn(model, "parse").andReturn(localResponse);
      model.fetch({ serverResponse: serverResponse });

      expect(model.get("name")).toBe("Test");
      expect(parseSpy).toHaveBeenCalledWith(serverResponse);

  describe "Fetching a collection", ->
    it "first pases the server response to the parse method of the collection", ->
      collection = new Collection();
      model = new Model { id: 1, name: "OldName" }
      collection.add(model);

      serverResponse = {
        Models: [
          Model: {
            id: 1,
            name: "Test"
          },
          Model: {
            id: 2,
            name: "Other"
          }
        ]
      }
      localResponse = [ { id: 1, name: "Test" }, { id: 2, name: "Other"}]

      parseSpy = spyOn(collection, "parse").andReturn(localResponse)
      modelParseSpy = spyOn(Model.prototype, "parse").andCallThrough()
      collection.fetch({ serverResponse: serverResponse })

      expect(parseSpy).toHaveBeenCalledWith(serverResponse, jasmine.any(Object))

      # First calls for updating the model in local storage
      expect(modelParseSpy.argsForCall[0][0]).toEqual({ id: 1, name: "Test" })
      expect(modelParseSpy.argsForCall[1][0]).toEqual({ id: 2, name: "Other" })

      # call from thorax to update the real instance
      expect(modelParseSpy.argsForCall[2][0]).toEqual({ id: 1, name: "Test" })
      expect(modelParseSpy.argsForCall[3][0]).toEqual({ id: 2, name: "Other" })

      expect(collection.length).toBe(2)
      expect(collection.get(1).get("name")).toBe("Test")
      expect(collection.get(2).get("name")).toBe("Other")

  describe "Creating a model instance", ->
    it "the server response should be parsed with parse", ->
      model = new Model { name: "Old name" }

      serverResponse = { Model: { id: 1, name: "test" } }
      localResponse = { id: 1, name: "Test" }

      parseSpy = spyOn(model, "parse").andReturn(localResponse);

      model.save({}, { serverResponse: serverResponse });

      expect(parseSpy).toHaveBeenCalledWith(serverResponse)
      expect(model.get("name")).toBe("Test")

  describe "Updating a model instance", ->
    it "the updated result from the server should be parsed using model.parse to adopt the format", ->
      model = new Model { id: 1, name: "Old name" }

      serverResponse = { Model: { id: 1, name: "test" } }
      localResponse = { id: 1, name: "Test" }

      parseSpy = spyOn(model, "parse").andReturn(localResponse);

      model.save({}, { serverResponse: serverResponse });

      expect(parseSpy).toHaveBeenCalledWith(serverResponse)
      expect(model.get("name")).toBe("Test")

  describe "Updating a model instance with a temporary id", ->
    it "should parse the result from the server", ->
      model = new Model { name: "Old name" }
      model.save({}, { remote: false }) # get temp id

      serverResponse = { Model: { id: 1, name: "test" } }
      localResponse = { id: 1, name: "Test" }

      parseSpy = spyOn(model, "parse").andReturn(localResponse);

      model.save({}, { serverResponse: serverResponse });

      expect(parseSpy).toHaveBeenCalledWith(serverResponse)
      expect(model.get("name")).toBe("Test")


  describe "Parse local fetched entities", ->
    describe "Create new entry", ->
      it "should pass the model as json instead of it's attributes to parse", ->
        model = new Model { name: "Old name" }

        parseSpy = spyOn(model, "parse").andCallThrough()
        model.save({}, { remote: false })

        expect(parseSpy.argsForCall[0][0]).not.toBeUndefined()
        expect(parseSpy.argsForCall[0][0].subCollection).not.toBeUndefined()
        #We expect an array (json serialized collection) and not the defaults collection
        expect(parseSpy.argsForCall[0][0].subCollection).toEqual([])
        expect(model.id).not.toBeUndefined()
        expect(model.get("name")).toBe("Old name")

