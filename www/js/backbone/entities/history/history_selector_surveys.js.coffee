@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The History Surveys Entity manages the survey_titles for user history.

  currentSurveys = false

  class Entities.UserHistorySurveysNav extends Entities.UserHistorySelectorNav

  API =
    init: ->
      currentSurveys = new Entities.UserHistorySurveysNav [], 
        parse: true
        filterType: 'survey_title'
      currentSurveys.chooseByName currentSurveys.defaultLabel

    getSurveys: (entries) ->
      currentSurveys = new Entities.UserHistorySurveysNav entries, 
        parse: true
        filterType: 'survey_title'
      currentSurveys

  App.on "before:start", ->
    API.init()

  App.reqres.setHandler "history:selector:surveys", (entries) ->
    API.getSurveys entries
