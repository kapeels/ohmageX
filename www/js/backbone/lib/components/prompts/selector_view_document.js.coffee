@Ohmage.module "Components.Prompts", (Prompts, App, Backbone, Marionette, $, _) ->

  class Prompts.Document extends Prompts.Base
    template: "prompts/document"
    triggers:
      'change input[type=file]': "file:changed"

    initialize: ->
      super
      @listenTo @, 'file:changed', @processFile
      @listenTo @model, 'change:currentValue', @render

    readFileEnd: (options) ->
      {file, success} = options
      if !App.device.isNative
        success()
        return false

      # reads the end of a file before processing
      start = file.size - 2;
      end = file.size - 1;
      reader = new FileReader();
      blob = file.slice start, end

      abortTimer = window.setTimeout (=>
          # automatically abort the read operation if it takes longer than 15 seconds.
          reader.abort()
        ), 15000

      reader.onloadend = (evt) =>
        if evt.target.readyState is FileReader.DONE
          window.clearTimeout abortTimer
          App.vent.trigger "filemeta:read:complete"

      reader.onload = (evt) =>
        App.vent.trigger "filemeta:read:success", file
        success()

      reader.onerror = (evt) =>

        switch evt.target.error.code
          when evt.target.error.NOT_FOUND_ERR
            App.vent.trigger "filemeta:read:error:notfound", file.name
          when evt.target.error.NOT_READABLE_ERR
            App.vent.trigger "filemeta:read:error:unreadable", file.name
          when evt.target.error.ABORT_ERR
            App.vent.trigger "filemeta:read:error:abort", file.name, file.size
          else
            App.vent.trigger "filemeta:read:error:general", file.name

      App.vent.trigger "loading:show", "Verifying file..."

      reader.readAsBinaryString blob

    processFile: ->
      fileDOM = @$el.find('input[type=file]')[0]
      myInput = fileDOM.files[0]

      if myInput
        # STOPGAP - file extension encoded in UUIDs

        console.log 'myFile input file type', myInput.type

        if App.request("system:file:name:is:valid", myInput.name) and !App.request("system:file:name:is:video", myInput.name) and !App.request("system:file:name:is:image", myInput.name)

          @readFileEnd
            file: myInput
            success: =>
              fileExt = myInput.name.match(/\.[0-9a-z]+$/i)[0]

              @model.set 'currentValue',
                fileObj: myInput
                fileName: myInput.name
                UUID: App.request('system:file:generate:uuid', fileExt)
                # UUID: _.guid()
                fileSize: myInput.size

        else
          App.vent.trigger "system:file:ext:invalid", myInput.name
          @model.set 'currentValue', false
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
