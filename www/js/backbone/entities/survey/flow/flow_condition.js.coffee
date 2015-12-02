@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The Flow Entity contains data related to the flow
  # of the Steps within a Survey.
  # This module contains the Condition handlers for Flow.

  # References the current Flow StepCollection object, defined in flow_init.js.coffee
  # via the interface "flow:current"

  API =
    checkCondition: (currentFlow, stepId) ->
      result = currentFlow.findWhere({id: stepId })
      throw new Error "Flow id #{stepId} does not exist in currentFlow" if typeof result is 'undefined'

      # evaluate all hidden prompts as false, do not show
      if result.get('status') is 'hidden' then return false

      myRawCondition = result.get 'condition'

      if @parseCondition(myRawCondition, App.request "responses:current")
        App.vent.trigger "flow:condition:success", stepId
        return true
      else
        # condition fails
        App.vent.trigger "flow:condition:failed", stepId
        return false

    parseCondition: (rawCondition, currentResponses) ->
      # rawCondition: Condition string from XML, to be parsed
      # currentResponses: ResponseCollection

      if rawCondition is true or rawCondition is false then return rawCondition

      # use all responses to evaluate the values of the step's Condition
      result = App.request "oldcondition:evaluate", rawCondition, currentResponses
      console.log "oldcondition:evaluate", result
      result

    containsInvalidFutureReference: (flow, condition) ->
      console.log 'containsInvalidFutureReference'
      steps = _.chain(flow.toJSON()).map((step)->{id: step.id,status: step.status }).sortBy('id').reverse().value()
      # We sort it by id, extract the ids and statuses, then reverse the order.
      # The purpose of this is to ensure step IDs are evaluated
      # so that if a longer ID happens to contain a shorter stepID inside of itself,
      # the longer ID is evaluated first, and it can be removed from the
      # condition string during future comparisons.

      if typeof condition is "string"
        # only check string-based conditions, boolean conditions won't contain any references
        result = _.find steps, (step, index) =>
          if condition.indexOf(step.id) is -1
            return false
          else
            # the condition contains a reference to a stepId.

            # Delete that stepId from the condition, so that next
            # time if this long stepId contains a shorter stepId
            # within itself, it doesn't evaluate the shorter stepId.
            # use regEx with 'g' to remove ALL instances of the stepId.
            condition = condition.replace(new RegExp(step.id,'g'), '')

            # the step referenced is either currently displaying or pending,
            # meaning it's a future reference.
            return step.status in ['pending','displaying','skipped_displaying']
        # if there were matches, that means there's a future reference in the condition
        return typeof result isnt "undefined"
      else
        return false

  App.reqres.setHandler "flow:condition:check", (id) ->
    currentFlow = App.request "flow:current"
    API.checkCondition currentFlow, id

  App.reqres.setHandler "flow:condition:invalid:future:reference", (condition) ->
    currentFlow = App.request "flow:current"
    API.containsInvalidFutureReference currentFlow, condition
