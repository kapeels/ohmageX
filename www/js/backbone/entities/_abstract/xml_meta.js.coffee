@Ohmage.module "Entities", ((Entities, App, Backbone, Marionette, $, _, xmlToJSON) ->

  # XML Meta entity.
  # Information about general XML metadata, used to store additional
  # metadata about campaigns, surveys, and prompts from the XML.
  # Note that this module includes an extra parameter "xmlToJSON"
  # that is passed in from the global scope.

  API =
    init: ->
      App.xmlMeta =
        rootLabel: "ohmagexmeta"

    xmlToJSON: (xmlText) ->
      # convert to JSON with the library's default options.
      xmlToJSON.parseString xmlText

  App.on "before:start", ->
    API.init()

  App.reqres.setHandler "xmlmeta:xml:to:json", (xmlText) ->
    if xmlText is false then return false
    API.xmlToJSON xmlText

), xmlToJSON
