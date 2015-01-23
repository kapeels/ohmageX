@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # Reminders entity.
  # Note: Local notification permissions are a concern for iOS 8+.

  class Entities.Reminder extends Entities.Model

  class Entities.Reminders extends Entities.Collection
    model: Entities.Reminder

  currentReminders = false

  API =
    init: ->
      App.request "storage:get", 'reminders', ((result) =>
        # saved reminders retrieved from raw JSON.
        console.log 'saved reminders retrieved from storage'
        currentReminders = new Entities.Reminders result
        App.vent.trigger "reminders:saved:init:success"
      ), =>
        console.log 'saved reminders not retrieved from storage'
        currentReminders = new Entities.Reminders
        App.vent.trigger "reminders:saved:init:failure"

    getReminders: ->
      currentReminders

    clear: ->
      currentReminders = new Entities.Reminders

      App.execute "storage:clear", 'reminders', ->
        console.log 'saved reminders erased'
        App.vent.trigger "reminders:saved:cleared"

  App.on "before:start", ->
    API.init()

  App.commands.setHandler "reminders:saved:clear", ->
    API.clear()

  App.vent.on "credentials:cleared", ->
    API.clear()

  App.reqres.setHandler "reminders:current", ->
    API.getReminders()