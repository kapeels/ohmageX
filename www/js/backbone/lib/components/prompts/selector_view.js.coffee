@Ohmage.module "Components.Prompts", (Prompts, App, Backbone, Marionette, $, _) ->

  class Prompts.Base extends App.Views.ItemView
    initialize: ->
      # Every prompt needs a gatherResponses method,
      # which will gather all response fields for the
      # response:get handler, activated when the prompt
      # needs to be validated.
      App.vent.on "survey:response:get", (surveyId, stepId) =>
        if stepId is @model.get('id') then @gatherResponses(surveyId, stepId)


  class Prompts.Text extends Prompts.Base
    template: "prompts/text"

    serializeData: ->
      data = @model.toJSON()
      console.log 'serializeData data', data
      if !data.currentValue
        data.currentValue = ''
      data

    gatherResponses: (surveyId, stepId) =>
      response = @$el.find('textarea').val()
      @trigger "response:submit", response, surveyId, stepId


  class Prompts.Unsupported extends Prompts.Base
    className: "text-container"
    template: "prompts/unsupported"
    gatherResponses: (surveyId, stepId) =>
      # just submit an unsupported prompt response as "NOT_DISPLAYED".
      # The status within Flow isn't actually set as "not_displayed"
      # because we still need to render the unsupported prompt
      # placeholder. Also, this is a Prompt because we still need
      # to submit a value for this Response inside the Response object.
      @trigger "response:submit", "NOT_DISPLAYED", surveyId, stepId
