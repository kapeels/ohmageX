@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The upload tracker Entity tracks whether
  # the user is currently uploading responses to the server.

  isUploading = false

  API =
    setActive: ->
      isUploading = true
    setInactive: ->
      isUploading = false

  App.reqres.setHandler "uploadtracker:uploading", ->
    isUploading

  App.vent.on "uploadtracker:active", ->
    isUploading = true

  App.vent.on "survey:exit survey:reset credentials:cleared uploadtracker:complete uploadqueue:all:complete", ->
    isUploading = false
