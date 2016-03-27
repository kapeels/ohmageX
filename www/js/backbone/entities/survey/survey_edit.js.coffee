@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This sets up the survey for editing.

  currentEditId = false

  API =
    prepopulate: (responses) ->
      # expects responses to be array of objs in format:
      # stepId: # Id of survey step to prepopulate
      # value: # value of survey step to prepopulate

      # this assumes that all responses are formatted
      # for their prompts as required by the flow_entity
      # currentValueType of 'default'

      # also does NOT prepopulate hidden prompts, since
      # those ignore the flow:prepop currentValue entirely.

      throw new Error "survey:edit prepopulate() responses not array, type #{typeof responses}" unless _.isArray(responses)

      _.each responses, (response) =>
        App.execute "flow:prepop:add", response.stepId, response.value


  App.reqres.setHandler "surveyedit:enabled", ->
    !!currentEditId

  App.reqres.setHandler "surveyedit:id", -> currentEditId

  App.vent.on "survey:exit survey:reset credentials:cleared", ->
    currentEditId = false
