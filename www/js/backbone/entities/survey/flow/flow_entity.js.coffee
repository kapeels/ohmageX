@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The Flow Entity contains data related to the flow
  # of the Steps within a Survey.
  # This module contains the Entity handlers for Flow.
  # This is a reference to fetching individual Prompt Entities
  # for a flow, based on its type.

  # References the current Flow StepCollection object, defined in flow_init.js.coffee
  # via the interface "flow:current"

  API =
    setCurrentValue: (responseEntity, id) ->
      # the currentValue attribute represents a saved value for the
      # current flow step's entity. This is pulled from either a response (if the user
      # is navigating back to a step they have already successfully
      # saved a response for), or a default value, defined in the prompt's
      # XML config.

      # the currentValueType is an attribute that indicates the source
      # of where the currentValue came from. This is currently needed for specific prompts
      # multi_choice_custom and single_choice_custom, where the source of the currentValue
      # determines how it must be parsed in the View.
      # Values for this are 'response' and 'default'

      currentValue = false

      if App.request "flow:type:is:prompt", id
        myResponse = App.request("response:get", id).get 'response'
        myDefault = if App.request("flow:prepop:get", id) isnt false
          App.request("flow:prepop:get", id)
        else
          responseEntity.get('default') or false
        validResponse = !!myResponse
        validDefault = myDefault isnt false

        if validResponse
          currentValue = myResponse
          responseEntity.set 'currentValueType', 'response'
        else if validDefault
          currentValue = myDefault
          responseEntity.set 'currentValueType', 'default'

      responseEntity.set 'currentValue', currentValue
      responseEntity

    getEntity: (currentStep, id, options) ->
      _.defaults options,
        setValue: true

      myType = currentStep.get 'type'
      $myXML = currentStep.get '$XML'
      # Only set our entity if it hasn't been initialized yet.
      # This way the entity's individual XML is rapidly parsed only when needed.
      if currentStep.get('entity') is false then currentStep.set( 'entity', App.request "prompt:entity", myType, $myXML )
      if options.setValue then @setCurrentValue(currentStep.get('entity'), id) else currentStep.get('entity')

  App.reqres.setHandler "flow:entity", (id, options = {}) ->
    currentStep = App.request "flow:step", id
    API.getEntity currentStep, id, options
