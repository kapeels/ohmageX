@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This sets up the survey for editing.

  currentEditId = false

  API =
    prepopulate: (responses) ->
      # expects responses to be array of objs in format:
      # stepId: # Id of survey step to prepopulate
      # value: # value of survey step to prepopulate

  App.reqres.setHandler "surveyedit:enabled", ->
    !!currentEditId

  App.reqres.setHandler "surveyedit:id", -> currentEditId

  App.vent.on "survey:exit survey:reset credentials:cleared", ->
    currentEditId = false
