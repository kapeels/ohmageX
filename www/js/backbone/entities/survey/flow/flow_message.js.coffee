@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The Flow Message entity handles returning data relevant to message
  # prompts in the flow.

  API =
    getValue: (step) ->
      switch step.get('status')
        when 'skipped'
          return 'SKIPPED'
        when 'not_displayed'
          return 'NOT_DISPLAYED'
        else
          return false
    getMessageIds: (flow) ->
      if !!!flow.where(type: 'message') then return false
      _.chain(flow.toJSON()).where(type: 'message').pluck('id').value()

  App.reqres.setHandler "flow:message:value", (stepId) ->
    messageStep = App.request "flow:step", stepId
    throw new Error "flow:message:value message type expected for step #{stepId}" unless messageStep.get('type') is 'message'
    API.getValue messageStep

  App.reqres.setHandler "flow:message:ids", ->
    currentFlow = App.request "flow:current"
    API.getMessageIds currentFlow
