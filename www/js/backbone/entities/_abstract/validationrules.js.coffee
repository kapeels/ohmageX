@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This contains all of the Rules for the given field's
  # validation. We use a basic Object instead of a BB
  # model to keep the definition simple. This object is intended
  # to be created privately within the `validate` method of an
  # Entity that uses it, so it does not need an event interface.

  # it uses the Decorator pattern to add Rules and execute all
  # added rules as needed on the passed-in properties.

  class Entities.ValidationRules
    constructor: (options) ->
      # this expects the options object to contain:
      # value - the response value
      # rulesMap - the properties in [{ruleName: compareValue}] format
      @errors = []
      # extracts a list of rules to execute from the rulesMap.
      console.log 'options.rulesMap', options.rulesMap
      @rulesList = _.map(options.rulesMap, (compareValue, ruleName) -> 
        ruleName
      )
      @validate options

    rules:
      # Rules expect that the comparison value they're using
      # has the same name as the rule.
      minLength:
        validate: (options) ->
          {value, rulesMap} = options
          if value.length < parseInt(rulesMap.minLength)
            @errors.push 'value too short.'
      maxLength:
        validate: (options) ->
          {value, rulesMap} = options
          if value.length > parseInt(rulesMap.maxLength)
            @errors.push 'value too long.'
      minValue:
        validate: (options) ->
          {value, rulesMap} = options
          if rulesMap.wholeNumber is "false"
            valueNum = parseFloat(value)
            minValue = parseFloat(rulesMap.minValue)
          else
            valueNum = parseInt(value)
            minValue = parseInt(rulesMap.minValue)
          if valueNum < minValue
            @errors.push 'value too low.'
      maxValue:
        validate: (options) ->
          {value, rulesMap} = options
          if rulesMap.wholeNumber is "false"
            valueNum = parseFloat(value)
            minValue = parseFloat(rulesMap.minValue)
          else
            valueNum = parseInt(value)
            maxValue = parseInt(rulesMap.maxValue)
          if valueNum > maxValue
            @errors.push 'value too high.'
      wholeNumber:
        validate: (options) ->
          {value, rulesMap} = options
          if rulesMap.wholeNumber is "false"
            # allow decimal numbers only.
            validChars = /^\-?[0-9]+(\.[0-9]+)?$/i
            if !validChars.test(value)
              @errors = ["Not a valid decimal number."]
          else
            # allow whole numbers only.
            validChars = /^\-?[0-9]+$/i
            if !validChars.test(value)
              @errors = ["Not a valid whole number."]

    validate: (options) ->
      console.log 'rulesList', @rulesList
      _.each(@rulesList, (ruleName) =>
        @rules[ruleName].validate.call(@, options)
      )
      @errors