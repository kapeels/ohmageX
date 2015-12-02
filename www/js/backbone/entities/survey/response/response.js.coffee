@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The Response Entity contains data related to the responses
  # within a given Survey.

  # currentResponses
  # "responses:init" initializes a ResponseCollection that persists in memory.
  # This collection is removed with "responses:destroy"
  currentResponses = false

  class Entities.ResponseProperty extends Entities.Model
    # response properties for validation

  class Entities.Response extends Entities.Model
    defaults: # default values for all Responses:
      response: false # All responses are false by default, updated with status before upload
      # properties: the getValidationProperties method initializes this
      # type: the promptType

  class Entities.ResponseValidated extends Entities.ValidatedModel
    defaults:
      response: false

  class Entities.TextResponse extends Entities.ResponseValidated
    validate: (attrs, options) ->
      myRulesMap =
        minLength: 'min'
        maxLength: 'max'
      super attrs, options, myRulesMap

  class Entities.NumberResponse extends Entities.ResponseValidated
    validate: (attrs, options) ->
      # set wholeNumber to default to true
      if !attrs.properties.wholeNumber? then attrs.properties.wholeNumber = "true"
      myRulesMap =
        minValue: 'min'
        maxValue: 'max'
        wholeNumber: 'wholeNumber'
      super attrs, options, myRulesMap

  class Entities.TimestampResponse extends Entities.ResponseValidated
    validate: (attrs, options) ->
      # defining a placeholder value here,
      # so a property can be passed into the rulesMap.
      attrs.properties.timestampISO = true
      myRulesMap =
        timestampISO: 'timestampISO'
      super attrs, options, myRulesMap

  class Entities.FileResponse extends Entities.ResponseValidated
    validate: (attrs, options) ->
      if !attrs.properties.maxFilesize? then attrs.properties.maxFilesize = App.custom.prompt_defaults.doc.max_bytes
      myRulesMap =
        maxSize: 'maxFilesize'
      super attrs, options, myRulesMap

  class Entities.VideoResponse extends Entities.ResponseValidated
    validate: (attrs, options) ->
      if !attrs.properties.max_seconds? then attrs.properties.max_seconds = App.custom.prompt_defaults.video.max_seconds

      console.log "source is #{attrs.response.source}"

      if attrs.response.source is "library"
        # we don't have the duration, calculate a file size based on seconds.
        bytes_per_second = App.custom.prompt_defaults.video.assumed_mb_per_minute * 1000000 / 60
        attrs.properties.maxFilesize = bytes_per_second * attrs.properties.max_seconds
        myRulesMap =
          maxSize: 'maxFilesize'
      else
        # the native Video capture checks duration on record. No need to validate here.
        myRulesMap = {}
      super attrs, options, myRulesMap


  class Entities.ResponseCollection extends Entities.Collection
    initialize: (options) ->
      if options.properties? then @set 'properties', new Entities.ResponseProperty options.properties
    model: (attrs, options) ->

      switch attrs.type
        when "text"
          new Entities.TextResponse attrs, options
        when "number"
          new Entities.NumberResponse attrs, options
        when "timestamp"
          new Entities.TimestampResponse attrs, options
        when "document"
          new Entities.FileResponse attrs, options
        when "video"
          new Entities.VideoResponse attrs, options
        else
          new Entities.Response attrs, options


  API =
    init: ($surveyXML) ->
      throw new Error "responses already initialized, use 'responses:destroy' to remove existing responses" unless currentResponses is false
      myResponses = @createResponses App.request("survey:xml:content", $surveyXML)
      currentResponses = new Entities.ResponseCollection myResponses
      console.log 'currentResponses', currentResponses.toJSON()
      App.vent.trigger "responses:init:complete", currentResponses
    getValidationProperties: ($xml, type) ->
      if type in ['single_choice', 'single_choice_custom','multi_choice','multi_choice_custom']
        return false
      $properties = $xml.find("property")
      propObj = {}
      _.each($properties, (child) ->
        $child = $(child)
        propObj[$(child).tagText("key")] = $(child).tagText('label')
      )
      propObj
    getOptions: ($xml, type) ->
      if !(type in ['single_choice', 'multi_choice'])
        return false
      $options = $xml.find("property")
      propObj = {}
      _.each($options, (child) ->
        $child = $(child)
        propObj[$(child).tagText("key")] = $(child).tagText('label')
      )
      propObj
    createResponses: ($contentXML) ->
      # Loop through all responses.
      # Only want to create a Response for a contentItem that actually
      # can accept responses, so we check its type. Currently a "message"
      # is the only item that does not have a response.
      # The .map() creates a new array, each key is object or false.
      # The .filter() removes the false keys.

      _.chain($contentXML.children()).map((child) =>
        $child = $(child)
        myType = $child.tagText('promptType')
        isResponseType = $child.prop('tagName') is 'prompt'
        if isResponseType 
          return {
            id: $child.tagText('id')
            type: myType
            question: $child.tagText('promptText')
            properties: @getValidationProperties($child, myType)
            options: @getOptions($child, myType)
          }
        else
          return false
      ).filter((result) -> !!result).value()
    containsFile: ->
      responses = @getResponses()
      fileResponseTypes = ["document"]
      result = responses.find (response) ->
        response.get('type') in fileResponseTypes and response.get('response') isnt false
      console.log 'containsFile result', result
      typeof result isnt "undefined"
    containsVideo: ->
      responses = @getResponses()
      fileResponseTypes = ["video"]
      result = responses.find (response) ->
        response.get('type') in fileResponseTypes and response.get('response') isnt false
      console.log 'containsFile result', result
      typeof result isnt "undefined"
    getUploadType: ->
      if @containsVideo() and App.request('survey:files')
        return 'video'
      else if @containsFile()
        return 'file'
      else
        return 'default'

    getResponses: ->
      throw new Error "responses not initialized, use 'responses:init' to create new Responses" unless currentResponses isnt false
      currentResponses
    getResponsesWithFlow: ->
      responses = @getResponses()
      responses.each (response) =>
        response.set 'status', App.request("flow:step", response.get('id')).get('status')
      # return JSON so responses can be easily added to localStorage
      responses.toJSON()
    destroyResponses: ->
      currentResponses = false


  App.commands.setHandler "responses:init", ($surveyXML) ->
    API.init $surveyXML

  App.reqres.setHandler "responses:current", ->
    API.getResponses()

  App.reqres.setHandler "responses:current:flow", ->
    API.getResponsesWithFlow()

  App.reqres.setHandler "responses:uploadtype", ->
    API.getUploadType()

  App.reqres.setHandler "response:get", (id) ->
    currentResponses = API.getResponses()
    myResponse = currentResponses.get(id)
    throw new Error "response id #{id} does not exist in currentResponses" if typeof myResponse is 'undefined'
    myResponse

  App.vent.on "survey:exit survey:reset", ->
    API.destroyResponses()
