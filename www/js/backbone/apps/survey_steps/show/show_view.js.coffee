@Ohmage.module "SurveyStepsApp.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Progress extends App.Views.ItemView
    template: "survey_steps/show/progress"
    serializeData: ->
      data = @model.toJSON()
      data.percentage = ((data.position / data.duration)*100).toFixed(1)
      data

  class Show.BaseButton extends App.Views.ItemView
    attributes: ->
      if @model.get('disabled') then { class: "disabled" }

  class Show.SkipButton extends Show.BaseButton
    template: "survey_steps/show/skipbutton"
    triggers:
      "click": "skip:clicked"

  class Show.PrevButton extends Show.BaseButton
    template: "survey_steps/show/prevbutton"
    triggers:
      "click": "prev:clicked"

  class Show.NextButton extends Show.BaseButton
    template: "survey_steps/show/nextbutton"
    triggers:
      "click": "next:raw:clicked"

    initialize: ->
      @activateNext = _.debounce(@activateNext, 2000, true)
      @listenTo @, "next:raw:clicked", @activateNext

    activateNext: ->
      @trigger "next:clicked"

  class Show.Layout extends App.Views.Layout
    className: 'survey-step'
    template: "survey_steps/show/show_layout"
    regions:
      noticeRegion: '#notice-region'
      progressRegion: '#progress'
      stepBodyRegion: '#step-body'
      skipButtonRegion: '#skip-button'
      prevButtonRegion: '#prev-button'
      nextButtonRegion: '#next-button'
