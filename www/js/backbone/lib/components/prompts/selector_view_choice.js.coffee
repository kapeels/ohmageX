@Ohmage.module "Components.Prompts", (Prompts, App, Backbone, Marionette, $, _) ->

  class Prompts.BaseComposite extends App.Views.CompositeView
    initialize: ->
      App.vent.on "survey:response:get", (surveyId, stepId) =>
        if stepId is @model.get('id') then @gatherResponses(surveyId, stepId)


  class Prompts.SingleChoiceItem extends App.Views.ItemView
    tagName: ->
      if App.custom.appearance.prompt_horizontal_single_choice is true
        'td'
      else
        'tr'
    className: ->
      if App.custom.appearance.prompt_horizontal_single_choice is true
        'horizontal-layout'
      else
        ''
    getTemplate: ->
      if App.custom.appearance.prompt_horizontal_single_choice is true
        "prompts/single_choice_item_horizontal"
      else
        "prompts/single_choice_item"

    template: "prompts/single_choice_item"
    triggers:
      "click button.delete": "customchoice:remove"


  class Prompts.SingleChoice extends Prompts.BaseComposite
    getTemplate: ->
      if App.custom.appearance.prompt_horizontal_single_choice is true
        "prompts/single_choice_horizontal"
      else
        "prompts/single_choice"

    childView: Prompts.SingleChoiceItem

    childViewContainer: ".prompt-list"

    selectChosen: (currentValue) ->
      # activate a choice selection based on the currentValueType.
      myChosenValue = switch @model.get('currentValueType')
        when 'response'
          # Saved responses are formatted as an object.
          # Reference the key property.
          currentValue.key
        when 'default'
          # Default responses are formatted as an individual key.
          # Just use the raw value.
          currentValue

      @$el.find("input[value='#{myChosenValue}']").prop('checked', true)

    onRender: ->
      currentValue = @model.get('currentValue')
      if currentValue isnt false then @selectChosen(currentValue)

    getResponseMeta: ->

      $checkedInput = @$el.find('input[type=radio]').filter(':checked')

      if !!!$checkedInput.length then return false

      myKey = $checkedInput.val()

      return {
        key: if isNaN(myKey) then myKey else parseInt(myKey)
        label: $checkedInput.parent().parent().find('label.canonical').text()
      }

    gatherResponses: (surveyId, stepId) =>
      @trigger "response:submit", @getResponseMeta(), surveyId, stepId


  class Prompts.MultiChoiceItem extends Prompts.SingleChoiceItem
    tagName: 'tr'
    getTemplate: -> "prompts/multi_choice_item"
    className: ''


  class Prompts.MultiChoice extends Prompts.SingleChoice
    getTemplate: -> "prompts/multi_choice"
    childView: Prompts.MultiChoiceItem
    childViewContainer: ".prompt-list"

    defaultStringToParsed: (defaultString) ->
      if defaultString.indexOf(',') isnt -1 and defaultString.indexOf('[') is -1
        # Check for values that contain a comma-separated list of
        # numbers with NO brackets (multi_choice default allows this)
        # which isn't a proper JSON format to convert to an array.
        # Add the missing brackets.
        defaultString = "[#{defaultString}]"
      try
        defaultParsed = JSON.parse(defaultString)
      catch Error
        console.log "Error, saved response string #{defaultString} failed to convert to array. ", Error
        return false
      defaultParsed

    selectChosen: (currentValue) ->
      chosenArr = switch @model.get('currentValueType')
        when 'default'
          valueParsed = @defaultStringToParsed currentValue
          result = []
          if !Array.isArray(valueParsed)
            # It's not an array, it's a single value.
            # Just set the value immediately.
            @$el.find("input[value='#{valueParsed}']").prop('checked', true)
            # We're done here! leave result as an empty array so we
            # don't iterate over it later.
          else
            result = valueParsed
          result
        when 'response'
          # just extract the keys meta property from the response.
          currentValue.keys

      _.each(chosenArr, (chosenValue) =>
        console.log 'chosenValue', chosenValue
        @$el.find("input[value='#{chosenValue}']").prop('checked', true)
      )

    getResponseMeta: ->
      # extracts response metadata from keys.

      $responses = @$el.find('input[type=checkbox]').filter(':checked')

      if !!!$responses.length then return false

      keys = []
      labels = []
      _.each( $responses, (response) ->
        myKey = $(response).val()
        keys.push( if isNaN(myKey) then myKey else parseInt(myKey) )
        labels.push $(response).parent().parent().find('label.canonical').text()
      )
      return {
        keys: keys
        labels: labels
      }
