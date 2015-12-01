@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The Campaigns Meta entity manages the campaign
  # entity's meta property containing custom metadata.

  App.commands.setHandler "campaigns:meta:set", (urn, $metaXML) ->
    App.vent.trigger "campaigns:meta:update", urn, App.request( 'xmlmeta:xml:to:json', "<contents>#{$metaXML}</contents>" )
    

  App.reqres.setHandler "campaigns:meta:get", (urn) ->
    App.request('campaign:entity', urn).get('meta')
