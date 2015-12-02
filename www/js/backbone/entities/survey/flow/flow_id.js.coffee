@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The Flow Entity contains data related to the flow
  # of the Steps within a Survey.
  # This module contains the ID handlers for Flow.

  # References the current Flow StepCollection object, defined in flow_init.js.coffee
  # via the interface "flow:current"

  API =
    firstId: (currentFlow) ->
      # Only return the first model that we receive from the condition check.
      # (hidden prompts don't count)
      # Then return its id.
      result = currentFlow.find((step) ->
        step.get('condition') isnt false and step.get('status') isnt 'hidden'
      )
      throw new Error "All Flow step conditions are false" if typeof result is 'undefined'
      result.get 'id'
    currentIndex: (currentFlow, id) ->

      currentStep = currentFlow.get id
      myIndex = currentFlow.indexOf currentStep
      throw new Error "id #{id} is not in currentFlow" if myIndex is -1
      myIndex

    nextId: (currentFlow, id) ->
      myIndex = @currentIndex currentFlow, id

      result = currentFlow.at(myIndex+1)
      throw new Error "id #{id} in currentFlow has no next id" if typeof result is 'undefined'
      result.get 'id'

    prevId: (currentFlow, id) ->
      # returns the previous ID that has a status of "complete".

      myIndex = @currentIndex currentFlow, id

      firstId = API.firstId(currentFlow)
      firstIndex = currentFlow.indexOf currentFlow.get(firstId)

      # return false if we're on the first flow step.
      if myIndex is firstIndex then return false

      prevIndex = false
      currentFlow.each( (model, key) ->
        if key < myIndex and model.get('status') is 'complete'
          prevIndex = key
      )

      # No prevIndex was found, meaning there were no
      # "complete" steps before this one. But we're not at
      # the first index, so jump to the first step.
      if !prevIndex then prevIndex = firstIndex

      result = currentFlow.at prevIndex

      result.get 'id'

  App.reqres.setHandler "flow:id:first", ->
    currentFlow = App.request "flow:current"
    API.firstId currentFlow

  App.reqres.setHandler "flow:id:next", (id) ->
    currentFlow = App.request "flow:current"
    API.nextId currentFlow, id

  App.reqres.setHandler "flow:id:previous", (id) ->
    currentFlow = App.request "flow:current"
    API.prevId currentFlow, id
