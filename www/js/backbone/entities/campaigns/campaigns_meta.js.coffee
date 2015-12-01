@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The Campaigns Meta entity manages the campaign
  # entity's meta property containing custom metadata.

  API =
    setMetaProperty: (campaign, metaJSON) ->
      campaign.set "meta", metaJSON

  App.commands.setHandler "campaigns:meta:set", (urn, $metaXML) ->
    metaJSON = App.request( 'xmlmeta:xml:to:json', "<contents>#{$metaXML}</contents>" )
    API.setMetaProperty App.request('campaign:entity', urn), metaJSON
    App.vent.trigger "campaigns:meta:update", urn, metaJSON
    

  App.reqres.setHandler "campaigns:meta:get", (urn) ->
    App.request('campaign:entity', urn).get('meta')
