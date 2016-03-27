@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This handles passing history entry edit info to
  # the survey_edit handler.


  API =
    processResponses: (surveyId, responses) ->

      # reset the entries files queue
      entriesFilesQueue = false

      prepop_responses = API.mapToPrepop responses

      # document/video response - file must be converted to an HTML5 fileObj
      # photo - file must be converted to base64
      #
      # queue entries:
      # uuid: response.prompt_response
      # type: response.prompt_type - used to switch between converting to fileObj or base64 (photo)
      # stepId: response.id

      # no file queue yet, just call the survey edit directly
      # this is the event that would fire when the queue resolves.
      App.execute "survey:edit",
        survey_response_id: surveyId
        prepop_responses: prepop_responses

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
          when "photo", "document", "video" then false # skip media
          else response.prompt_response

        if myValue is false then return false

        return {
          stepId: response.id
          value: myValue
        }
      ).filter((result) -> !!result).value()

      # returns false if there are no valid responses.
      if results.length is 0 then return false

      results

  App.commands.setHandler "history:entry:edit", (entry) ->
    API.processResponses entry.get('id'), entry.get('responses')
