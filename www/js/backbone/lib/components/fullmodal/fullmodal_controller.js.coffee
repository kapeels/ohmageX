@Ohmage.module "Components.FullModal", (FullModal, App, Backbone, Marionette, $, _) ->

  # The FullModal component is an alternative to the
  # mainRegion. It overlaps the mainRegion when activated,
  # and includes its own close button. Options such as
  # a callback (that triggers when the Close button is activated)
  # can be sent to this component.

  # In any view that uses this, it's advised that the
  # closeCallback fires events that the parent view
  # can use for cleanup, since the mainRegion is unaffected 
  # by this view.

  class FullModal.FullModalController extends App.Controllers.Application

    initialize: (options) ->
      { view, config } = options

      config = if _.isBoolean(config) then {} else config

      _.defaults config,
        closeCallback: false

      @layout = @getLayoutView()

      @listenTo App.vent, "fullmodal:close", =>
        # close the full modal
        console.log 'close the full modal'
        @layout.trigger "close:clicked"

      @listenTo @layout, "content:reset", =>
        # close the layout when the content has reset
        if config.closeCallback isnt false
          config.closeCallback()

        @layout.destroy()

      @listenTo @layout, "show", =>
        console.log "show fullmodal layout"
        @contentRegion view

      @show @layout

    contentRegion: (realView) ->
      @show realView, region: @layout.contentRegion

    getLayoutView: ->
      new FullModal.Layout

  App.commands.setHandler "show:fullmodal", (view, options) ->
    new FullModal.FullModalController
      view: view
      config: options.modal
      region: App.fullModalRegion

  App.vent.on "system:notifications:clicked", ->
    # close an active modal when a notification has been selected
    App.vent.trigger "fullmodal:close"
