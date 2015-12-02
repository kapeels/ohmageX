@Ohmage.module "SurveysApp.List", (List, App, Backbone, Marionette, $, _) ->

  # Surveys List currently renders a list of ALL available surveys
  # for a user, retrieved from the server.

  class List.Controller extends App.Controllers.Application

    initialize: (options) ->
      if options.campaign_id
        surveys = App.request "surveys:saved:campaign", options.campaign_id
      else if options.category
        surveys = App.request "surveys:saved:category", options.category
      else
        surveys = App.request "surveys:saved"

      if options.category
        selector = App.request "surveys:selector:category", options.category
      else
        selector = App.request "surveys:selector:entities", options.campaign_id

      @layout = @getLayoutView selector

      @listenTo selector, "change:chosen", (model) =>
        # this event fires every time all instances of the
        # `chosen` attribute within the model are changed.
        # So only activate when our model is "chosen"
        if model.isChosen() then App.vent.trigger("survey:list:campaign:selected", model)

      @listenTo @layout, "show", =>
        console.log "show list layout"
        @infobuttonRegion selector
        @selectorRegion selector
        @surveysRegion surveys

      @listenTo @layout, "link:campaigns:clicked", =>
        App.vent.trigger "surveys:list:link:campaigns:clicked"

      @show @layout, loading: false

    infoRegion: (campaign) ->
      infoView = App.request "campaigninfo:view", campaign

      @show infoView, region: @layout.infoRegion

    infobuttonRegion: (selector) ->
      infoView = @getInfoButtonView selector

      @listenTo infoView, "info:clicked", (args) =>
        console.log 'info:clicked args', args
        @infoRegion args.model


      @show infoView, region: @layout.infobuttonRegion

    selectorRegion: (selector) ->
      selectorView = @getSelectorView selector

      @show selectorView, region: @layout.selectorRegion

    surveysRegion: (surveys) ->
      surveysView = @getSurveysView surveys

      @listenTo surveysView, "childview:running:clicked", (child, args) ->
        console.log 'childview:running:clicked args', args.model
        App.vent.trigger "survey:list:running:clicked", args.model

      @listenTo surveysView, "childview:stopped:clicked", (child, args) ->
        console.log 'childview:stopped:clicked args', args.model
        App.vent.trigger "survey:list:stopped:clicked", args.model

      @show surveysView, region: @layout.listRegion

    getInfoButtonView: (selector) ->
      new List.CampaignInfoButton
        collection: selector

    getSelectorView: (selector) ->
      new List.CampaignsSelector
        collection: selector

    getSurveysView: (surveys) ->
      new List.Surveys
        collection: surveys

    getLayoutView: (selector) ->
      new List.Layout
        collection: selector
