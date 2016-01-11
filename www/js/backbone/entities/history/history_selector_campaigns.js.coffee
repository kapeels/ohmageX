@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The History Campaigns Entity manages the campaigns for user history.

  currentCampaigns = false

  class Entities.UserHistoryCampaignsNav extends Entities.UserHistorySelectorNav

