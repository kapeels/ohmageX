@Ohmage.module "SurveyStepsApp", (SurveyStepsApp, App, Backbone, Marionette, $, _) ->

  class SurveyStepsApp.Router extends Marionette.AppRouter
    before: ->
      if !App.request("credentials:isloggedin")
        App.navigate Routes.default_route(), trigger: true
        return false
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
      # update URL without triggering the Router
      App.navigate "survey/#{surveyId}/step/#{stepId}"
      new SurveyStepsApp.Show.Controller
        stepId: stepId
        surveyId: surveyId

    goPrev: (surveyId, stepId) ->
      prevId = App.request "flow:id:previous", stepId
      if prevId
        App.vent.trigger "survey:step:goback", surveyId, stepId
        App.navigate "survey/#{surveyId}/step/#{prevId}", { trigger: true }
      else
        # There is no previous ID.
        App.execute "dialog:confirm", "Do you want to exit the #{App.dictionary('page','survey')}?", =>
          App.vent.trigger "survey:exit", surveyId

    goNext: (surveyId, stepId) ->
      nextId = App.request "flow:id:next", stepId
      # call the Router method without updating the URL
      @checkStep surveyId, nextId

  App.addInitializer ->
    new SurveyStepsApp.Router
      controller: API

  App.on "before:start", ->

    if App.custom.functionality.multi_question_survey_flow is false

      App.vent.on "survey:step:skip:clicked", (surveyId, stepId) ->
        console.log "survey:step:skip:clicked"
        # navigate to the next item and broadcast a skipped event
        App.vent.trigger "survey:step:skipped", stepId
        API.goNext surveyId, stepId

      App.vent.on "survey:step:prev:clicked", (surveyId, stepId) ->
        console.log "survey:step:prev:clicked"
        API.goPrev surveyId, stepId

      App.vent.on "survey:intro:next:clicked survey:message:next:clicked", (surveyId, stepId) ->
        console.log "survey:intro:next:clicked survey:message:next:clicked"
        API.goNext surveyId, stepId

      App.vent.on "survey:beforesubmit:next:clicked", (surveyId, stepId) ->
        # survey:upload gathers and submits all data
        # and will fire survey:upload:success.
        App.commands.execute "survey:upload", surveyId

      App.vent.on "survey:upload:success survey:upload:failure:ok", (response, surveyId) ->
        # Go to the next step if the submit succeeds or if they click the OK button on the modal
        server_id = App.request("survey:saved:server_id", surveyId)
        API.goNext surveyId, "#{server_id}beforeSurveySubmit"

      App.vent.on "survey:aftersubmit:next:clicked", (surveyId, stepId) ->
        App.vent.trigger "survey:exit", surveyId

      App.vent.on "reminders:survey:new", (surveyId) ->
        App.vent.trigger "survey:reset", surveyId

      App.vent.on "survey:notifications:suppress", (surveyId, notificationIds) ->
        App.vent.trigger "survey:exit", surveyId

      App.vent.on "response:set:success", (response, surveyId, stepId) ->
        API.goNext surveyId, stepId

      App.vent.on "response:set:error", (error) ->
        console.log "response:set:error", error
        App.execute "dialog:alert", "#{error.toString()}"
