@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The Campaigns Meta entity manages the campaign
  # entity's meta property containing custom metadata.

  API =
    setMetaProperty: (campaign, $metaXML) ->
      campaign.set "meta", App.request( 'xmlmeta:xml:to:json', "<contents>#{$metaXML}</contents>" )

  App.commands.setHandler "campaigns:meta:set", (urn, $metaXML) ->
    API.setMetaProperty App.request('campaign:entity', urn), $metaXML

  App.reqres.setHandler "campaigns:meta:get", (urn) ->
    App.request('campaign:entity', urn).get('meta')
