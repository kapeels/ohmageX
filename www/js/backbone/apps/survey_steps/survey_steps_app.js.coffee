@Ohmage.module "SurveyStepsApp", (SurveyStepsApp, App, Backbone, Marionette, $, _) ->

  class SurveyStepsApp.Router extends Marionette.AppRouter
    appRoutes:
      "survey/:surveyId/step/:stepId": "checkStep"

  API =
    checkStep: (surveyId, stepId) ->
      console.log "checkStep #{stepId}"

      # Redirect to the start of the survey 
      # if survey isn't initialized before proceeding.
      # TODO: persist currentFlow in localStorage for refresh
      if not App.request "flow:init:status" 
        App.navigate "survey/#{surveyId}", trigger: true
        return false

      isPassed = App.request "flow:condition:check", stepId

      if isPassed
        @showStep surveyId, stepId
      else
        @goNext surveyId, stepId

    showStep: (surveyId, stepId) ->
      new SurveyStepsApp.Show.Controller
        stepId: stepId
        surveyId: surveyId

    goPrev: (surveyId, stepId) ->
      prevId = App.request "flow:id:prev", stepId
      App.navigate "survey/#{surveyId}/step/#{prevId}", { trigger: true }

    goNext: (surveyId, stepId) ->
      nextId = App.request "flow:id:next", stepId
      App.navigate "survey/#{surveyId}/step/#{nextId}", { trigger: true }

  App.addInitializer ->
    new SurveyStepsApp.Router
      controller: API
  
  App.vent.on "survey:step:prev:clicked", (stepId) ->
    console.log "survey:step:prev:clicked"
    App.historyBack()

  App.vent.on "survey:intro:next:clicked survey:message:next:clicked", (surveyId, stepId) ->
    console.log "survey:intro:next:clicked survey:message:next:clicked"
    API.goNext surveyId, stepId

  App.vent.on "survey:beforesubmit:next:clicked", (surveyId, stepId) ->
    # gather and submit all data
    # Go to the next step if the submit succeeds

  App.vent.on "survey:aftersubmit:next:clicked", (surveyId, stepId) ->
    # for now, just go back to the beginning of the survey
    App.navigate "survey/#{surveyId}"

  App.vent.on "response:set:success", (response, surveyId, stepId) ->
    API.goNext surveyId, stepId

  App.vent.on "response:set:error", (error) ->
    console.log "response error", error
