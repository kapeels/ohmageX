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
        }
      ).filter((result) -> !!result).value()

      # returns false if there are no valid responses.
      if results.length is 0 then return false
      new Entities.Collection results



  App.commands.setHandler "history:entry:edit", (entry) ->
    API.processResponses entry.get('id'), entry.get('responses')
  App.vent.on "survey:start history:edit:queue:all:error", ->
    App.vent.trigger "loading:hide"

    editMediaQueue = false
    currentPrepopResponses = false

