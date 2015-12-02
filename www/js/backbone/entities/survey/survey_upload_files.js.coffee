@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The survey Entity deals with data relating to a single survey.
  # This module handles file processing for a single survey upload.

  # currentFiles
  currentFiles = false
  fileUUIDs = false

  API =
    addSurveyFile: (responseValue) ->
      if !currentFiles then currentFiles = {}
      if !fileUUIDs then fileUUIDs = []
      currentFiles[responseValue.UUID] = responseValue.fileObj
      fileUUIDs.push(responseValue.UUID)
      console.log "!!! responseValue #{JSON.stringify(responseValue)}"
      console.log "!!! fileUUIDs #{JSON.stringify(fileUUIDs)}"
      console.log "!!! currentFiles #{JSON.stringify(currentFiles)}"

    getFilesHash: ->
      console.log 'currentFiles', currentFiles
      currentFiles
    getFirst: ->
      if currentFiles
        return currentFiles[fileUUIDs[0]]
      else
        return false
    getFirstUUID: ->
      if currentFiles
        return fileUUIDs[0]
      else
        return false
    updateFileObj: (uuid, fileObj) ->
      console.log 'survey:files:update new fileObj path', fileObj.localURL
      currentFiles[uuid] = fileObj

  App.commands.setHandler "survey:file:add", (responseValue) ->
    API.addSurveyFile responseValue

  App.reqres.setHandler "survey:files", ->
    API.getFilesHash()

  App.reqres.setHandler "survey:files:first:file", ->
    API.getFirst()

  App.reqres.setHandler "survey:files:first:uuid", ->
    API.getFirstUUID()

  App.commands.setHandler "survey:files:destroy", ->
    currentFiles = false
    fileUUIDs = false

  App.commands.setHandler "survey:files:update", (uuid, fileObj) ->
    # update an existing file object by UUID.
    API.updateFileObj uuid, fileObj

  App.vent.on "survey:exit survey:reset", ->
    currentFiles = false
    fileUUIDs = false
