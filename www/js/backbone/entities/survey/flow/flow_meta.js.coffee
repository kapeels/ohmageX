@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The flow meta entity handles extracting meta information for an item in the Flow.
  # This uses the custom `meta` property defined when the flow is first created.

  API =
    getMetaText: (currentStep, prop) ->
      meta = currentStep.get 'meta'
      if meta and meta.hasOwnProperty prop
        meta[prop][0]._text
      else
        false

  App.reqres.setHandler 'flow:meta:property:text', (id, property) ->
    # extracts simple text property (no nesting)
    currentStep = App.request "flow:step", id
    API.getMetaText currentStep, property
