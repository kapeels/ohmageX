@Ohmage.module "SurveyStepsApp.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Progress extends App.Views.ItemView
    template: "survey_steps/show/progress"
    serializeData: ->
      data = @model.toJSON()
      data.percentage = ((data.position / data.duration)*100).toFixed(1)
      data

  class Show.SkipButton extends App.Views.ItemView
    template: "survey_steps/show/skipbutton"
    triggers:
      "click button": "skip:clicked"

  class Show.PrevButton extends App.Views.ItemView
    template: "survey_steps/show/prevbutton"
    triggers:
      "click button": "prev:clicked"

  class Show.NextButton extends App.Views.ItemView
    template: "survey_steps/show/nextbutton"
    triggers:
      "click button": "next:clicked"

  class Show.Layout extends App.Views.Layout
    template: "survey_steps/show/show_layout"
    regions:
      noticeRegion: '#notice'
      progressRegion: '#progress'
      stepBodyRegion: '#step-body'
      skipButtonRegion: '#skip-button'
      prevButtonRegion: '#prev-button'
      nextButtonRegion: '#next-button'
