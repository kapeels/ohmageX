@Ohmage.module "ProfileApp.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Profile extends App.Views.ItemView
    className: "text-container"
    template: "profile/show/info"
    triggers:
      "click .change-password": "password:clicked"
      "click .clear-cache": "clear:cache:clicked"
      "change #enable-switch-wifi": "toggle:wifi"

    initialize: ->
      @listenTo @, "toggle:wifi", @toggleWifi

    toggleWifi: ->
      if @$el.find('#enable-switch-wifi').prop('checked')
        @trigger "wifiuploadonly:enabled"
      else
        @trigger "wifiuploadonly:disabled"

    serializeData: ->
      data = @model.toJSON()
      data.showCache = App.device.isNative
      data.showPassword = App.request "credentials:ispassword"
      data.serverPath = App.request "serverpath:current"

      data
    onRender: ->
      if @model.get('wifi_upload_only') is true then @$el.find("#enable-switch-wifi").prop('checked', true)

  class Show.Layout extends App.Views.Layout
    template: "profile/show/show_layout"
    regions:
      profileRegion: "#profile-region"
