@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The flow Hidden entity handles initializing and preparing all hidden flow items
  # for a given survey.

  # async warning: Flow hidden initializes after the flow:init:complete event.
  # This event does not block subsequent events from happening such as responses:init,
  # followed by survey:start.
  # It's possible that a survey could start with hidden prompts not initialized. 
  # Assuming that doesn't happen right now. if there are errors with hidden prompt 
  # behavior such as rendering or data missing, this may need to be accounted for.

  API =
    initHidden: (flow) ->

      flow.each (step) =>
        myId = step.get('id')
        myHidden = App.request 'flow:meta:property:text', myId, 'hidden'
        if myHidden isnt false
          # we have a hidden prompt. Begin initializing.
          throw new Error "Only random values for hidden prompt #{myId} implemented, #{myHidden} not valid" if myHidden isnt 'random'

          throw new Error "hidden prompt #{myId} must be a number prompt, is #{step.get('type')}" if step.get('type') isnt 'number'

          step.set 'status', 'hidden'

          # initialize the flow entity for this step, but don't set its value yet.
          myEntity = App.request("flow:entity", myId, setValue: false)

          propertiesNotSet = typeof myEntity.get('properties') is "undefined" or 
            typeof myEntity.get('properties').get('min') is "undefined" or 
            typeof myEntity.get('properties').get('max') is "undefined"
          throw new Error "hidden prompt min and/or max properties not set" if  propertiesNotSet

          # extract the min and max properties from myEntity.
          minValue = parseInt myEntity.get('properties').get('min')
          maxValue = parseInt myEntity.get('properties').get('max')
          # generate a random number between min and max
          myRandom = Math.floor(Math.random() * maxValue) + minValue

          # This does not use currentValue in flow entity, currentValue is used to populate
          # prompts during view rendering. No view is rendered, the response will
          # be set directly on the response entity when responses are initialized.
          # We instead set a new property on the flow step. Later, when hidden responses initialize,
          # they set using this property.
          console.log "hidden prompt #{myId} random value", myRandom
          step.set 'hidden_value', myRandom


  App.vent.on "flow:init:complete", (flow) ->
    API.initHidden flow
