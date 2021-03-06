@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The Campaigns Latest entity provides an interface
  # for the most recent campaign.

  API =
    getLatest: (campaigns) ->
      # Get maximum campaign creation timestamp
      # by coverting the date to an epoch
      if campaigns is false or campaigns.length is 0 then return false
      campaigns.max (campaign) -> moment(campaign.get('creation_timestamp')).valueOf()

  App.reqres.setHandler "campaigns:latest", ->
    API.getLatest App.request("campaigns:saved:current")
