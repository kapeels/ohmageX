@Ohmage.module "Components.Prompts", (Prompts, App, Backbone, Marionette, $, _) ->

  class Prompts.Document extends Prompts.Base
    template: "prompts/document"
    triggers:
      'change input[type=file]': "file:changed"

    initialize: ->
      super
      @listenTo @, 'file:changed', @processFile
      @listenTo @model, 'change:currentValue', @render

    processFile: ->
      fileDOM = @$el.find('input[type=file]')[0]
      myInput = fileDOM.files[0]

      if myInput
        # STOPGAP - file extension encoded in UUIDs
        fileExt = myInput.name.match(/\.[0-9a-z]+$/i)

        # Hardcode any blank file extensions to .mp4
        # for Android video.
        fileExt = if !!!fileExt then '.mp4' else fileExt[0]
        console.log 'myFile Extension', fileExt
        @model.set 'currentValue',
          fileObj: myInput
          fileName: myInput.name
          UUID: App.request('system:file:generate:uuid', fileExt)
          # UUID: _.guid()
          fileSize: myInput.size
      else
        @model.set 'currentValue', false

    serializeData: ->
      data = @model.toJSON()
      console.log 'serializeData data', data

      if !data.currentValue
        data.fileName= 'Select a Document File'
      else
        data.fileName = "Selected File: #{data.currentValue.fileName}"

      data

    gatherResponses: (surveyId, stepId) =>
      response = @model.get('currentValue')
      @trigger "response:submit", response, surveyId, stepId
