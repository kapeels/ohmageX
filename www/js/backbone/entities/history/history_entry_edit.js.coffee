@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This handles passing history entry edit info to
  # the survey_edit handler.


  API =
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
          else response.prompt_response

      ).filter((result) -> !!result).value()

      results

  App.commands.setHandler "history:entry:edit", (entry) ->
    API.processResponses entry.get('id'), entry.get('responses')
