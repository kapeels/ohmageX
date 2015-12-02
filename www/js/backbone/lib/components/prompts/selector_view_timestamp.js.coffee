@Ohmage.module "Components.Prompts", (Prompts, App, Backbone, Marionette, $, _) ->

  class Prompts.Timestamp extends Prompts.Base
    template: "prompts/timestamp"

    padWithZero: (number) ->
      if number < 10 then '0'+number else number

    serializeData: ->
      data = @model.toJSON()
      console.log 'serializeData data', data
      if data.currentValue
        currentDate = new Date(data.currentValue)
        data.currentDateValue = data.currentValue.substring(0,10)
      else
        currentDate = new Date()
        dd = @padWithZero(currentDate.getDate())
        mm = @padWithZero(currentDate.getMonth()+1) # January is 0
        yyyy = currentDate.getFullYear()

        # browser environment date input checks
        if (Modernizr.inputtypes.date)
          # use a value that will be detected and converted
          # by the browser datepicker.
          data.currentDateValue = "#{yyyy}-#{mm}-#{dd}"
        else
          # no native support for input type 'date'.
          # Set the value in the proper format.
          data.currentDateValue = "#{mm}/#{dd}/#{yyyy}"

      data.currentTimeValue = "#{@padWithZero(currentDate.getHours())}:#{@padWithZero(currentDate.getMinutes())}:#{@padWithZero(currentDate.getSeconds())}"
      data

    gatherResponses: (surveyId, stepId) =>
      myDate = @$el.find('input[type=date]').val()
      myTime = @$el.find('input[type=time]').val()
      offset = new Date().toString().match(/([-\+][0-9]+)\s/)[1]
      response = "#{myDate} #{myTime}#{offset}"
      @trigger "response:submit", response, surveyId, stepId
