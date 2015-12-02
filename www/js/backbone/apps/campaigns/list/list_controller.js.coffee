@Ohmage.module "CampaignsApp.List", (List, App, Backbone, Marionette, $, _) ->

  class List.Controller extends App.Controllers.Application

    initialize: ->
      campaigns = App.request "campaigns:filtered", App.request("campaigns:user")

      selector = App.request "campaigns:selector:entities"

      if selector.chosenName() is 'Saved'
        campaigns.where({ saved: true })

      @listenTo campaigns, "filter:saved:clear", =>
        # pass the filter clearing in campaigns
        # to the selector entity, so its view can update
        selector.trigger "filter:saved:clear"

      @listenTo selector, "change:chosen", (model) =>
        # this event fires every time all instances of the
        # `chosen` attribute within the model are changed.
        # So only activate when our model is "chosen"
        if model.isChosen()
          if model.get('name') is 'Saved'
            campaigns.where({ saved: true })
          else
            campaigns.where()

      @listenTo App.vent, 'surveys:saved:campaign:fetch:success surveys:saved:campaign:fetch:error', =>
        # Surveys entity does not hide the loader on fetch.
        # This allows other parts of the app to manage showing
        # and hiding the loader, such as this controller (when it's active)
        App.vent.trigger "loading:hide"

      @listenTo App.vent, 'surveys:saved:campaign:fetch:error', (id, message) =>
        App.execute "dialog:alert", message

      @layout = @getLayoutView campaigns

      @listenTo @layout, "show", =>
        console.log "show campaigns list layout"
        # @selectorRegion selector
        @searchRegion campaigns
        @campaignsRegion campaigns

      @show @layout, loading: true

    selectorRegion: (selector) ->
      selectorView = @getSelectorView selector

      @show selectorView, region: @layout.selectorRegion

    searchRegion: (campaigns) ->
      searchView = @getSearchView campaigns

      @show searchView, region: @layout.searchRegion

    infoRegion: (campaign) ->
      infoView = App.request "campaigninfo:view", campaign

      @show infoView, region: @layout.infoRegion

    campaignsRegion: (campaigns) ->
      campaignsView = @getCampaignsView campaigns

      @listenTo campaignsView, "childview:info:clicked", (child, args) =>
        console.log 'childview:info:clicked model', args.model
        @infoRegion args.model

      @listenTo campaignsView, "childview:unsave:clicked", (child, args) ->
        console.log 'childview:unsave:clicked args', args.model
        App.vent.trigger "campaign:list:unsave:clicked", args.model, child, campaigns.meta('filterType')

      @listenTo campaignsView, "childview:navigate:clicked", (child, args) ->
        console.log 'childview:navigate:clicked args', args.model
        App.vent.trigger "campaign:list:navigate:clicked", args.model

      @listenTo campaignsView, "childview:ghost:remove:clicked", (child, args) ->
        App.vent.trigger "campaign:list:ghost:remove:clicked", args.model

      @listenTo campaignsView, "childview:save:clicked", (child, args) ->
        console.log 'childview:save:clicked args', args.model
        App.vent.trigger "campaign:list:save:clicked", args.model

      @show campaignsView, region: @layout.listRegion

    getSearchView: (campaigns) ->
      new List.Search
        collection: campaigns

    getSelectorView: (selector) ->
      new List.SavedSelector
        collection: selector

    getCampaignsView: (campaigns) ->
      new List.Campaigns
        collection: campaigns

    getLayoutView: (campaigns) ->
      new List.Layout
        collection: campaigns
