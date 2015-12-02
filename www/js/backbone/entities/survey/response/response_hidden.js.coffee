@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The response Hidden entity handles initializing and preparing all hidden responses
  # for a given survey.

  # async warning: response hidden initializes after the response:init:complete event.
  # This event does not block subsequent events from happening such as condition check
  # or survey start.
  # It's possible that a survey could start with conditions referencing hidden prompts
  # failing to evaluate correctly. 
  # Assuming that doesn't happen right now. if there are errors with hidden prompt 
  # behavior, this may need to be accounted for.

  API =
    initHidden: (flow) ->
      flow.each (step) =>
        if step.get('status') is 'hidden'
          App.execute "response:set", step.get('hidden_value'), step.get('id')

  App.vent.on "responses:init:complete", ->
    API.initHidden App.request("flow:current")
