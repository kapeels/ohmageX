@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The History Campaigns Entity manages the campaigns for user history.

  currentCampaigns = false

  class Entities.UserHistoryCampaignsNav extends Entities.UserHistorySelectorNav

  API =
    init: ->
      currentCampaigns = new Entities.UserHistoryCampaignsNav [],
        parse: true
        filterType: 'campaign_urn'
      currentCampaigns.chooseByName currentCampaigns.defaultLabel

    getCampaigns: (entries) ->
      currentCampaigns = new Entities.UserHistoryCampaignsNav entries,
        parse: true
        filterType: 'campaign_urn'
      currentCampaigns

  App.on "before:start", ->
    API.init()

  App.reqres.setHandler "history:selector:campaigns", (entries) ->
    API.getCampaigns entries
