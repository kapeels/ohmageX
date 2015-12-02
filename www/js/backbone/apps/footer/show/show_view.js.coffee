@Ohmage.module "FooterApp.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Contents extends App.Views.ItemView
    template: "footer/show/_contents"
    openLink: (e) ->
      e.preventDefault()
      targetHref = $(e.currentTarget).attr('href')
      if App.device.isNative
        window.open targetHref, '_system'
      else
        window.open targetHref, '_blank'
    serializeData: ->
      data = {}
      data.version = App.version
      data.helpURL = App.custom.routes.help
      data
    events: ->
      if App.device.isNative
        "touchstart a": "openLink"
      else
        "click a": "openLink"

  class Show.Footer extends App.Views.Layout
    template: "footer/show/footer"
    tagName: "footer"
    regions:
      contentRegion: ".content-region"
