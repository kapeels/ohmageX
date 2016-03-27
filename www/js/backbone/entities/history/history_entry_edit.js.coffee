@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This handles passing history entry edit info to
  # the survey_edit handler.


  API =
    mapToPrepop: (responses) ->
      # returns an array of objects in following format:
      # stepId: # Id of survey step to prepopulate
      # value: # value of survey step to prepopulate


  App.commands.setHandler "history:entry:edit", (entry) ->
    API.processResponses entry.get('id'), entry.get('responses')
