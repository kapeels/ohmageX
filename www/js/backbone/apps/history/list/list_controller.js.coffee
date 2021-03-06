@Ohmage.module "HistoryApp.List", (List, App, Backbone, Marionette, $, _) ->

  # History List renders the history List view.

  class List.Controller extends App.Controllers.Application
    initialize: (options) ->

      @layout = @getLayoutView()
      campaigns = App.request "campaigns:saved:current"
      if campaigns.length isnt 0
        entries = App.request('history:entries:filtered', App.request("history:entries"))
        bucketsSelector = App.request "history:selector:buckets", App.request("history:entries")
        @buckets_filter = options.buckets_filter
        surveysSelector = App.request "history:selector:surveys", App.request("history:entries")
        campaignsSelector = App.request "history:selector:campaigns", App.request("history:entries")
        @campaigns_filter = options.campaigns_filter

      @listenTo @layout, "show", =>
        if campaigns.length is 0
          @noticeRegion "No saved #{App.dictionary('pages','campaign')}! Download #{App.dictionary('pages','campaign')} from the #{App.dictionary('pages','campaign').capitalizeFirstLetter()} Menu section to view your #{App.dictionary('page','history')}."
        else
          console.log "showing history layout"
          @bucketsRegion bucketsSelector, entries
          @surveysRegion surveysSelector, entries
          @campaignsRegion campaignsSelector, entries
          @listRegion entries

      if campaigns.length is 0
        loadConfig = false
      else
        loadConfig = entities: entries

      @show @layout, loading: loadConfig

    noticeRegion: (message) ->
      notice = new Backbone.Model message: message
      noticeView = @getNoticeView notice

      @show noticeView, region: @layout.noticeRegion

    bucketsRegion: (buckets, entries) ->
      @listenTo buckets, "change:chosen", (model) =>
        console.log 'change:chosen listener'
        # this listener must be in the controller,
        # any references to @entries inside of the selector
        # model are unable to trigger events or call methods
        # on @entries
        if model.isChosen()
          console.log 'model name to choose by', model.get('name')

          if model.get('name') is buckets.defaultLabel
            entries.trigger "filter:reset", 'bucket'
          else
            entries.trigger "filter:set", 'bucket', model.get('name')

      if @buckets_filter then buckets.chooseByName(@buckets_filter)

      bucketsView = @getFilterSelectorView 'bucket', buckets

      @show bucketsView, region: @layout.bucketsControlRegion

    surveysRegion: (surveys, entries) ->
      surveysView = @getFilterSelectorView 'survey_title', surveys

      @listenTo surveys, "change:chosen", (model) =>
        console.log 'change:chosen listener'
        # this listener must be in the controller,
        # any references to @entries inside of the selector
        # model are unable to trigger events or call methods
        # on @entries
        if model.isChosen()
          if model.get('name') is surveys.defaultLabel
            entries.trigger "filter:reset", 'survey_title'
          else
            entries.trigger "filter:set", 'survey_title', model.get('name')

      @show surveysView, region: @layout.surveysControlRegion

    campaignsRegion: (campaigns, entries) ->
      campaignsView = @getFilterSelectorView 'campaign_name', campaigns

      @listenTo campaigns, "change:chosen", (model) =>
        console.log 'change:chosen listener'
        # this listener must be in the controller,
        # any references to @entries inside of the selector
        # model are unable to trigger events or call methods
        # on @entries
        if model.isChosen()
          if model.get('name') is campaigns.defaultLabel
            entries.trigger "filter:reset", 'campaign_name'
          else
            entries.trigger "filter:set", 'campaign_name', model.get('name')

      if @campaigns_filter then campaigns.chooseByName(@campaigns_filter)

      @show campaignsView, region: @layout.campaignsControlRegion


    listRegion: (entries) ->
      listView = @getListView entries

      @listenTo listView, "childview:clicked", (args) =>
        console.log 'childview:entry:clicked', args.model
        # update the previous and next ids for
        # the activated model.
        entries.trigger "ids:adjacent:set", args.model.get('id')
        # fetching the model from entries so we pass in the modified model
        # with new adjacent IDs and not the base view's model.
        App.vent.trigger "history:list:entry:clicked", args.model.get('id')

      @listenTo App.vent, "history:entry:previous:clicked history:entry:next:clicked", (myId) =>
        # This is listening to an app level event - necessary
        # so that this list view can trigger itself to open.
        # This way the activation of next and previous properly handles
        # all of its necessary cleanup.
        entries.trigger "ids:adjacent:set", myId

        App.vent.trigger "history:list:entry:clicked", myId

      @show listView, region: @layout.listRegion

    getLayoutView: ->
      new List.Layout

    getNoticeView: (notice) ->
      new List.Notice
        model: notice

    getFilterSelectorView: (filterType, collection) ->
      new List.FilterSelector
        filterType: filterType
        collection: collection

    getListView: (entries) ->
      new List.Entries
        collection: entries
