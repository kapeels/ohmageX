@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This deals with campaign URNs.

  API =
    getCampaignUrns: (campaigns) ->
      campaigns.pluck 'id'

  App.reqres.setHandler "campaigns:saved:urns", ->
    campaigns = App.request "campaigns:saved:current"
    if campaigns.length is 0 then return false
    API.getCampaignUrns campaigns
