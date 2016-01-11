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

  App.on "before:start", ->
    API.init()

