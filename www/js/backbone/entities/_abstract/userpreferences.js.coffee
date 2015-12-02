@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # UserPrefences entity.
  # This pertains to storing, retrieving and setting user preferences.

  class Entities.UserPreferences extends Entities.Model

  storedPreferences = false

  API =
    init: ->
      App.request "storage:get", 'user_preferences', ((result) =>
        console.log 'saved user preferences retrieved from storage'
        storedPreferences = new Entities.UserPreferences result
        App.vent.trigger "userpreferences:saved:init:success"
      ), =>
        console.log 'saved user preferences not retrieved from storage'
        storedPreferences = new Entities.UserPreferences
          wifi_upload_only: App.custom.user_preference_defaults.wifi_upload_only
        App.vent.trigger "userpreferences:saved:init:failure"

    updateLocal: (callback) ->
      App.execute "storage:save", 'user_preferences', storedPreferences.toJSON(), callback

    getPreference: (preference) ->
      storedPreferences.get(preference)

    setPreference: (preference, state) ->
      storedPreferences.set(preference, state)
      @updateLocal( =>
        console.log "UserPreferences entity saved in localStorage"
      )

    clear: ->
      storedPreferences = new Entities.UserPreferences

      App.execute "storage:clear", 'user_preferences', ->
        console.log 'user preferences erased'
        App.vent.trigger "userpreferences:saved:cleared"

  App.on "before:start", ->
    API.init()

  App.reqres.setHandler "user:preferences:get", (preference) ->
    API.getPreference preference

  App.vent.on "user:preferences:wifiuploadonly:enabled", ->
    API.setPreference 'wifi_upload_only', true

  App.vent.on "user:preferences:wifiuploadonly:disabled", ->
    API.setPreference 'wifi_upload_only', false

  App.vent.on "credentials:cleared", ->
    API.clear()
