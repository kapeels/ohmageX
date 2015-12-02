@Ohmage.module "SurveyMultipromptApp", (SurveyMultipromptApp, App, Backbone, Marionette, $, _) ->

  class SurveyMultipromptApp.Router extends Marionette.AppRouter
    before: ->
      if !App.request("credentials:isloggedin")
        App.navigate Routes.default_route(), trigger: true
        return false
    appRoutes:
      "surveymulti/:surveyId/page/:page": "checkPage"
      "surveymulti/:surveyId/aftersubmit": 'afterSubmit'

  API =
    checkPage: (surveyId, page) ->
      console.log "checkPage", page

      # Redirect to the start of the survey
      # if survey isn't initialized before proceeding.
      if not App.request "flow:init:status"
        App.navigate "survey/#{surveyId}", trigger: true
        return false

      App.execute "surveytracker:page:set", page

      @showPage surveyId, page

    showPage: (surveyId, page) ->
      # update URL without triggering the Router
      App.navigate "surveymulti/#{surveyId}/page/#{page}"
      # console.log "updated flow with page numbers", App.request('flow:current').map (step) -> "\nid: #{step.get('id')}, page: #{step.get('page')}, condition: #{step.get('condition')}, status: #{step.get('status')}"

      new SurveyMultipromptApp.Show.Controller
        page: parseInt(page)
        surveyId: surveyId

    afterSubmit: (surveyId) ->
      # get the current flow's afterSubmit page number
      try
        @checkPage surveyId, App.request("flow:page:aftersubmit:page")
      catch
        # Redirect to the start of the survey
        # if attempting to get the aftersubmit page number throws an error
        App.navigate "survey/#{surveyId}", trigger: true

    goPrev: (surveyId) ->
      try
        prevPage = App.request "surveytracker:page:previous"
        # surveytracker:page:previous throws an exception if there is no previous page.

        # This needs to be triggered on each displaying step when navigating backwards
        # and the validation succeeds.
        # App.vent.trigger "survey:step:goback", surveyId, stepId

        App.navigate "surveymulti/#{surveyId}/page/#{prevPage}", { trigger: true }

      catch e
        # There is no previous page.
        App.execute "dialog:confirm", "Do you want to exit the #{App.dictionary('page','survey')}?", =>
          App.vent.trigger "survey:exit", surveyId

    goNext: (surveyId, page) ->
      nextPage = App.request "surveytracker:page:next", page
      # call the Router method without updating the URL
      @checkPage surveyId, nextPage

  App.addInitializer ->
    new SurveyMultipromptApp.Router
      controller: API

  App.on "before:start", ->

    if App.custom.functionality.multi_question_survey_flow is true
      console.log 'set app listeners here'


      App.vent.on "survey:direct:prev:clicked", (surveyId, page) ->
        # the direct event simply navigates back immediately, nothing to save or validate.
        console.log "survey:direct:prev:clicked"
        API.goPrev surveyId, page

      App.vent.on "survey:intro:next:clicked survey:prompts:next:clicked", (surveyId, page) ->
        console.log "survey:prompts:next:clicked"
        API.goNext surveyId, page

      App.vent.on "survey:beforesubmit:next:clicked", (surveyId) ->
        # survey:upload gathers and submits all data
        # and will fire survey:upload:success.
        App.commands.execute "survey:upload", surveyId

      App.vent.on "survey:upload:success survey:upload:failure:ok", (response, surveyId) ->
        # Go to the next step if the submit succeeds or if they click the OK button on the modal

        # Now we can display the single step flow's afterSubmit page.
        App.navigate "surveymulti/#{surveyId}/aftersubmit", trigger: true

      App.vent.on "survey:aftersubmit:next:clicked", (surveyId, stepId) ->
        App.vent.trigger "survey:exit", surveyId

      App.vent.on "reminders:survey:new", (surveyId) ->
        App.vent.trigger "survey:reset", surveyId

      App.vent.on "survey:notifications:suppress", (surveyId, notificationIds) ->
        App.vent.trigger "survey:exit", surveyId
