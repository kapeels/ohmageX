@Ohmage.module "Components.FullModal", (FullModal, App, Backbone, Marionette, $, _) ->

  class FullModal.Layout extends App.Views.Layout
    template: "fullmodal/layout"
    className: "fullmodal-container"
    triggers:
      "click .button-close": "close:clicked"
    regions:
      contentRegion: "article"

    initialize: ->
      @listenTo @, 'close:clicked', ->
        @modal.hide()
        setTimeout (=>
          # the purpose of this setTimeout
          # is to allow the FullModalComponent
          # to finish its animation before deleting
          # the contents of this modal.
          @contentRegion.reset()
          @trigger "content:reset"
        ), 400
    onAttach: ->
      @modal = new FullModalComponent('#fullmodal-root')
      @modal.show()
