@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This sets up the survey for editing.

  currentEditId = false

  App.reqres.setHandler "surveyedit:enabled", ->
    !!currentEditId

  App.reqres.setHandler "surveyedit:id", -> currentEditId

  App.vent.on "survey:exit survey:reset credentials:cleared", ->
    currentEditId = false
