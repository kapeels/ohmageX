@Ohmage.module "DashboardeQISApp.Show", (Show, App, Backbone, Marionette, $, _) ->

  # DashboardeQISApp renders the e-QIS dashboard.

  class Show.Controller extends App.Controllers.Application
    initialize: ->
      @layout = @getLayoutView()

      campaigns = App.request "campaigns:saved:current"

      @listenTo @layout, "show", =>
        if campaigns.length is 0
          @noticeRegion "No installed #{App.dictionary('pages','campaign').capitalizeFirstLetter()}. Tap the Menu bars in the top left corner and click #{App.dictionary('page','campaign').capitalizeFirstLetter()}. Then click on the Download icon."
        else
          console.log "showing layout"
          # reference the most recent campaign
          campaign = App.request 'campaigns:latest'
          artifacts = App.request 'dashboardeqis:artifacts', campaign
          @campaignRegion campaign
          @artifactsRegion artifacts, campaign

      @show @layout

    noticeRegion: (message) ->
      notice = new Backbone.Model message: message
      noticeView = @getNoticeView notice

      @show noticeView, region: @layout.noticeRegion


    campaignRegion: (campaign) ->
      campaignView = @getCampaignView campaign

      @show campaignView, region: @layout.campaignRegion

    artifactsRegion: (artifacts, campaign) ->
      artifactsView = @getArtifactsView artifacts

      @listenTo artifactsView, "childview:newsurvey:first:clicked", (child, args) ->
        console.log "childview:newsurvey:first:clicked", args.model
        App.vent.trigger "dashboardeqis:newsurvey:clicked", campaign.get('id'), args.model.get('surveyId'), args.model.get('newPrepopIndex'), args.model.get('newPrepopfirstSurveyStep')

      @listenTo artifactsView, "childview:newsurvey:second:clicked", (child, args) ->
        console.log "childview:newsurvey:second:clicked", args.model
        App.vent.trigger "dashboardeqis:newsurvey:clicked", campaign.get('id'), args.model.get('secondSurveyId'), args.model.get('newPrepopIndex'), args.model.get('newPrepopSecondSurveyStep')

      @listenTo artifactsView, "childview:responsecount:clicked", (child, args) ->
        console.log "childview:responsecount:clicked", args.model
        if args.model.get('responseCount') is 0
          App.execute "dialog:alert", "There are no responses to show for this category."
        else
          App.vent.trigger "dashboardeqis:responsecount:clicked", args.model.get 'navbucket'

      @show artifactsView, region: @layout.artifactsRegion

    getNoticeView: (notice) ->
      new Show.Notice
        model: notice

    getCampaignView: (campaign) ->
      new Show.Campaign
        model: campaign


    getArtifactsView: (artifacts) ->
      new Show.Artifacts
        collection: artifacts

    getLayoutView: ->
      new Show.Layout
