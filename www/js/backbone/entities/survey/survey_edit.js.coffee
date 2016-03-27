@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This sets up the survey for editing.

  currentEditId = false

  App.reqres.setHandler "surveyedit:enabled", ->
    !!currentEditId

