@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This handles passing history entry edit info to
  # the survey_edit handler.

  editMediaQueue = false

  currentPrepopResponses = false

  API =
    processResponses: (responses) ->

      # reset the entries files queue
      editMediaQueue = []
      currentPrepopResponses = false

      currentPrepopResponses = API.mapToPrepop responses

      console.log "****** currentPrepopResponses.toJSON()", currentPrepopResponses.toJSON()
      if editMediaQueue.length > 0
        # We have items to queue up for auto-download.
        # Edit mode is enabled, so this queue should
        # request confirmation before downloading videos.
        App.execute "history:media:queue:add", editMediaQueue
        App.execute "history:media:queue:download", "Fetching required files for editing..."
      else
        # no items to queue, just get the responses going.
        App.vent.trigger 'history:edit:queue:all:success'

    mapToPrepop: (responses) ->
      # returns an array of objects in following format:
      # stepId: # Id of survey step to prepopulate
      # value: # value of survey step to prepopulate

      # The .filter() removes the false keys.
      results = _.chain(responses).map( (response) ->
        # exclude not_displayed or skipped entries from prepopulating
        if response.prompt_response in ["NOT_DISPLAYED", "SKIPPED"] then return false


        # TODO: for video, document, photo prompt types,
        # add to queue for file caching
        myValue = switch response.prompt_type
          when "multi_choice", "multi_choice_custom" then JSON.stringify(response.prompt_response)
          when "photo", "document", "video"
            # add to queue for edit auto-download
            editMediaQueue.push
              context: if response.prompt_type is 'photo' then 'image' else 'media'
              id: response.prompt_response

            # set its value to the media uuid
            # so it can be linked back up with the queue
            response.prompt_response
          else response.prompt_response

        if myValue is false then return false

        return {
          stepId: response.id
          value: myValue
          uuid: if response.prompt_type in ["photo", "document", "video"] then myValue
        }
      ).filter((result) -> !!result).value()

      # returns false if there are no valid responses.
      if results.length is 0 then return false
      console.log "****** results", results
      new Entities.Collection results

    updatePrepopFileResponse: (uuid, context, fileEntry) ->
      # this method converts a file-based prepop response
      # from a uuid to an actual format that is needed for
      # prepopulating an image, doc, or video prompt.
      # since we have access to the file info when processing
      # the file auto-download queue, we can extract the
      # properties needed from fileEntry.

      myResponse = currentPrepopResponses.findWhere(value: uuid)

      if fileEntry is false or !App.device.isNative
        # remove from pre-populating completely
        # if no valid file entry is provided
        # or in browser mode
        currentPrepopResponses.remove myResponse

      else

        if context is 'auto:image'
          myResponse.set 'value', fileEntry.toURL()
        else
          # pass both doc and video filenames.
          # No conflicts, they should both work.
          # FileObj is not passed, because
          # unchanged uuids should be diffed and skipped
          # from uploading.

          fileURI = App.request("system:file:path",uuid)
          fileName = fileURI.split('/').pop()

          myResponse.set 'value',
            fileName: fileName
            UUID: uuid # just use the UUID from the file
            videoName: fileName



  App.commands.setHandler "history:entry:edit", (entry) ->
    # set edit flag immediately so the entire app is aware
    # that we're in edit mode
    App.execute "surveyedit:enable", entry.get('id')

    API.processResponses entry.get('responses')

  App.reqres.setHandler "history:edit:prepop:responses", ->
    currentPrepopResponses


  App.vent.on "filemeta:fetch:auto:success", (uuid, context, fileEntry = false) ->

    if App.request "surveyedit:enabled"
      API.updatePrepopFileResponse uuid, context, fileEntry

  App.vent.on "survey:exit survey:reset history:edit:queue:all:error", ->

    editMediaQueue = false
    currentPrepopResponses = false

  App.vent.on "history:edit:queue:all:success", ->
    App.vent.trigger "loading:hide"

    App.execute "survey:edit",
      prepop_responses: currentPrepopResponses.toJSON()
