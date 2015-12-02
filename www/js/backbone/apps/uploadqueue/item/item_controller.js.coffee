@Ohmage.module "Uploadqueue.Item", (Item, App, Backbone, Marionette, $, _) ->

  # Upload Queue item renders a single item in the upload queue.

  class Item.Controller extends App.Controllers.Application
    initialize: (options) ->
      { queue_id } = options
      @queue_id = queue_id

      @listenTo App.vent, 'uploadqueue:remove:success', (queue_id) =>
        if queue_id is @queue_id then App.vent.trigger("fullmodal:close")

      item = App.request "uploadqueue:item", @queue_id

      @layout = @getLayoutView item

      @listenTo @layout, "show", =>
        console.log "show item layout"
        @detailsRegion item
        responses = new Backbone.Collection item.get('responses')
        @responsesRegion responses
        @noticeRegion()

      @show @layout,
        loading: false
        modal:
          closeCallback: =>
            App.vent.trigger "uploadqueue:item:fullmodal:close"

    noticeRegion: ->
      App.execute "notice:region:set", @layout.noticeRegion

    detailsRegion: (item) ->
      detailsView = @getDetailsView item

      @listenTo detailsView, "delete:clicked", (args) =>
        console.log 'childview:delete:clicked', item
        App.vent.trigger "uploadqueue:list:delete:clicked", item

      @listenTo detailsView, "upload:clicked", (args) =>
        console.log 'item:upload:clicked', item
        App.vent.trigger "uploadqueue:list:upload:clicked", item

      @show detailsView, region: @layout.detailsRegion

    responsesRegion: (responses) ->
      responsesView = @getResponsesView responses

      @show responsesView, region: @layout.responsesRegion

    getResponsesView: (responses) ->
      new Item.Responses
        collection: responses

    getDetailsView: (item) ->
      new Item.Details
        model: item

    getLayoutView: (item) ->
      new Item.Layout
        model: item
