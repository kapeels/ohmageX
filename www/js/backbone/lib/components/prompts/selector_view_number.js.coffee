@Ohmage.module "Components.Prompts", (Prompts, App, Backbone, Marionette, $, _) ->

  class Prompts.Number extends Prompts.Base
    template: "prompts/number"
    triggers:
      "click button.increment": "value:increment"
      "click button.decrement": "value:decrement"

    initialize: ->
      super
      @listenTo @, 'value:increment', @incrementValue
      @listenTo @, 'value:decrement', @decrementValue

    incrementValue: ->
      $valueField = @$el.find("input[type='number']")
      myVal = $valueField.val()
      myVal = if !!!myVal.length or _.isNaN(myVal) then 0 else parseInt(myVal)
      if @model.get('properties').get('max') isnt undefined
        return if parseInt(@model.get('properties').get('max')) <= myVal
      $valueField.val(myVal+1)

    decrementValue: ->
      $valueField = @$el.find("input[type='number']")
      myVal = $valueField.val()
      myVal = if !!!myVal.length or _.isNaN(myVal) then 0 else parseInt(myVal)
      if @model.get('properties').get('min') isnt undefined
        return if parseInt(@model.get('properties').get('min')) >= myVal
      $valueField.val(myVal-1)

    serializeData: ->
      data = @model.toJSON()
      console.log 'serializeData data', data
      if !data.currentValue
        data.currentValue = ''
      data.min = false
      data.max = false

      if @model.get('properties').get('min') isnt undefined and @model.get('properties').get('max') isnt undefined
        data.min = @model.get('properties').get('min')
        data.max = @model.get('properties').get('max')

      data

    gatherResponses: (surveyId, stepId) =>
      response = @$el.find('input[type="number"]').val()
      @trigger "response:submit", response, surveyId, stepId
