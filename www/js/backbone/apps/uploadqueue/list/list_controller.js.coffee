@Ohmage.module "Uploadqueue.List", (List, App, Backbone, Marionette, $, _) ->

  # Upload Queue list renders the responses in the upload queue.

  class List.Controller extends App.Controllers.Application
    initialize: ->

      list = App.request "uploadqueue:entity"

      @layout = @getLayoutView list

      @listenTo @layout, "show", =>
        console.log "show list layout"
        @listRegion list
        @noticeRegion()

      @listenTo App.vent, "uploadqueue:item:fullmodal:close", =>
        @noticeRegion()

      @show @layout, loading: false

    noticeRegion: ->
      App.execute "notice:region:set", @layout.noticeRegion

    listRegion: (list) ->
      listView = @getListView list

      @listenTo listView, "childview:stopped:clicked", (args) =>
        console.log 'childview:stopped:clicked', args.model
        App.vent.trigger "uploadqueue:list:stopped:clicked", args.model

      @listenTo listView, "childview:delete:clicked", (args) =>
        console.log 'childview:delete:clicked', args.model
        App.vent.trigger "uploadqueue:list:delete:clicked", args.model

      @listenTo listView, "childview:running:clicked", (args) =>
        console.log 'childview:running:clicked', args.model
        App.vent.trigger "uploadqueue:list:running:clicked", args.model

      @listenTo listView, "childview:upload:clicked", (args) =>
        console.log 'childview:upload:clicked', args.model
        App.vent.trigger "uploadqueue:list:upload:clicked", args.model


      @show listView, region: @layout.listRegion

    getListView: (list) ->
      new List.Queue
        collection: list

    getLayoutView: (list) ->
      new List.Layout
        collection: list
