@Ohmage.module "SurveyMultipromptApp.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Progress extends App.Views.ItemView
    template: "survey_multiprompt/show/progress"
    serializeData: ->
      data = @model.toJSON()
      data.percentage = ((data.position / data.duration)*100).toFixed(1)
      data

  class Show.BaseButton extends App.Views.ItemView
    attributes: ->
      if @model.get('disabled') then { class: "disabled" }

  class Show.PrevButton extends Show.BaseButton
    template: "survey_multiprompt/show/prevbutton"
    triggers:
      "click": "prev:clicked"

  class Show.NextButton extends Show.BaseButton
    template: "survey_multiprompt/show/nextbutton"
    triggers:
      "click": "next:raw:clicked"

    initialize: ->
      @activateNext = _.debounce(@activateNext, 2000, true)
      @listenTo @, "next:raw:clicked", @activateNext

    activateNext: ->
      @trigger "next:clicked"

  class Show.StepError extends App.Views.ItemView
    attributes:
      "class": "inline-error"
    initialize: ->
      @model.set('customerror', '')

      @listenTo App.vent, "response:set:success", (errorText, surveyId, stepId) =>
        # clear errors on validation success
        if stepId is @model.get('id')
          @model.set('customerror', '')

      @listenTo App.vent, "survey:step:skipped_displaying", (stepId) ->
        # clear errors when a step is skipped
        if stepId is @model.get('id')
          @model.set('customerror', '')

      @listenTo App.vent, "response:set:error", (errorText, surveyId, stepId) =>
        console.log ' stepError response:set:error listener'

        if stepId is @model.get('id')
          @model.set('customerror', errorText)

      @listenTo @model, "change:customerror", @render

    template: "survey_multiprompt/show/_step_error"

  class Show.StepSkip extends App.Views.ItemView
    initialize: ->
      @listenTo @, "toggle:skip", @toggleSkip
    attributes:
      "class": "inline-skip"
    toggleSkip: ->
      if @$el.find('input').prop('checked')
        @trigger "skipped", @model.get('id')
      else
        @trigger "unskipped", @model.get('id')
    onRender: ->
      if @model.get('status') is "skipped_displaying" then @$el.find('input').prop('checked', true)
    template: "survey_multiprompt/show/_step_skip"
    triggers:
      "click":
        event: "toggle:skip"
        preventDefault: false
        stopPropagation: false

  class Show.StepLayout extends App.Views.Layout
    className: 'survey-step-item'

    initialize: ->
      @listenTo App.vent, "survey:step:skipped_displaying", (stepId) ->
        if @model.get('id') is stepId
          @$el.find('.step-body-region').addClass('skipped')
          @$el.removeClass('error')

      @listenTo App.vent, "survey:step:unskipped", (stepId) ->
        if @model.get('id') is stepId
          @$el.find('.step-body-region').removeClass('skipped')

      @listenTo App.vent, "response:set:error", (errorText, surveyId, stepId) =>
        if @model.get('id') is stepId
          @$el.addClass('error')

      @listenTo App.vent, "response:set:success", (errorText, surveyId, stepId) =>
        if @model.get('id') is stepId
          @$el.removeClass('error')

    onRender: ->
      if @model.get('status') is "skipped_displaying" then @$el.find('.step-body-region').addClass('skipped')
    template: "survey_multiprompt/show/_step_layout"
    regions:
      errorRegion: '.inline-error-region'
      skipButtonRegion: '.skip-button-region'
      stepBodyRegion: '.step-body-region'

  class Show.Steps extends App.Views.CollectionView
    childView: Show.StepLayout

  class Show.Layout extends App.Views.Layout
    className: 'survey-step survey-step-multi'
    template: "survey_multiprompt/show/show_layout"
    regions:
      noticeRegion: '#notice-region'
      progressRegion: '#progress'
      stepsLayoutRegion: '#step-body'
      prevButtonRegion: '#prev-button'
      nextButtonRegion: '#next-button'
