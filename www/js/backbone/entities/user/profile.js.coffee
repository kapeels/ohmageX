@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The profile Entity provides an interface for the logged-in user's profile.

  class Entities.UserProfile extends Entities.Model

  API =
    getProfile: ->
      new Entities.UserProfile 
        username: App.request('credentials:username')
        wifi_upload_only: App.request 'user:preferences:get', 'wifi_upload_only'

  App.reqres.setHandler "profile:current", ->
    API.getProfile()
