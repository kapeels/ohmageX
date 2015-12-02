@Ohmage.module "Components.Steps", (Steps, App, Backbone, Marionette, $, _) ->

  # This Step Selector instantiates a view to insert into the passed-in
  # region, based on retrieving a step via ID from currentFlow.
  # It references the currentFlow using the handlers 
  # "flow:type" and "flow:entity"

  class Steps.SelectorController extends App.Controllers.Application

    initialize: (options) ->
      { surveyId, stepId, type, entity } = options

      @surveyId = surveyId
      @stepId = stepId

      myView = @selectView entity, type

      if type is "message"
        messageTextMarkdown = App.request "prompt:markdown",
          originalText: entity.get 'messageText'
          campaign_urn: App.request "survey:saved:urn", @surveyId
          surveyId: @surveyId
          stepId: @stepId

        entity.set 'messageTextMarkdown', messageTextMarkdown

      if type is "afterSurveySubmit"
        @listenTo myView, 'new:reminder', =>
          App.vent.trigger "reminders:survey:new", @surveyId

        @listenTo myView, 'suppress:notifications', (notificationIds) =>
          App.vent.trigger "survey:notifications:suppress", @surveyId, notificationIds

      @showSelectedView myView

    selectView: (entity, type) ->
      switch (type)
        when "intro"
          return new Steps.Intro
            model: entity
        when "message"
          return new Steps.Message
            model: entity
        when "beforeSurveySubmit"
          return new Steps.BeforeSubmission
            model: entity
        when "afterSurveySubmit"

          if App.custom.functionality.post_survey_reminders_disabled or (!App.custom.build.debug and !App.device.isNative)
            # no debugging and no native, just show the base exit summary.
            return new Steps.AfterSubmission
              model: entity

          else

            if App.request('reminders:current').findWhere(surveyId: @surveyId)
              # reminders for this survey already exist

              reminders = App.request "reminders:survey:scheduled:latertoday", @surveyId

              if reminders.length is 0
                # Reminders exist but they're not later today.
                # just show the exit page.
                return new Steps.AfterSubmission
                  model: entity
              else
                # reminders are scheduled later today for this survey.
                return new Steps.AfterSuppressReminders
                  collection: App.request("notifications:survey:scheduled:latertoday", @surveyId)
            else
              # reminders don't exist for this survey at all.
              return new Steps.AfterNoReminders

        else
          # handle all other view types in the Prompts component.
          return App.request "prompts:view", @surveyId, @stepId, entity, type

    showSelectedView: (view) ->
      @show view

  App.commands.setHandler "steps:view:insert", (region, surveyId, stepId) ->
    result = new Steps.SelectorController
      region: region
      surveyId: surveyId
      stepId: stepId
      type: App.request "flow:type", stepId
      entity: App.request "flow:entity", stepId
