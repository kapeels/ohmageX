@Ohmage.module "SurveyMultipromptApp.Show", (Show, App, Backbone, Marionette, $, _) ->

  # renders multiple prompts on a given page.
  # A fundamental assumption of multiprompt rendering:
  # if a page begins with an intro, beforeSurveySubmit, or afterSurveySubmit step,
  # it is the ONLY step on that page. Any other assumption will break this layout.
  # This assumption is enforced in the flow_pages entity as well.

  class Show.Controller extends App.Controllers.Application
    initialize: (options) ->
      console.log "SurveyMultipromptApp Show.Controller"
      { surveyId, page } = options
      @surveyId = surveyId
      @page = page
      @firstStep = App.request "flow:page:step:first", @page

      @layout = @getLayoutView()

      @listenTo @layout, "show", =>
        @noticeRegion()
        @progressRegion()
        @stepsLayoutRegion()
        @prevButtonRegion()
        @nextButtonRegion()
        $('body').scrollTop App.request('surveys:scroll:position', @surveyId, @page)

      if App.request "flow:type:is:prompt", @firstStep.get('id')
        @addMultiResponseListeners()

      @listenTo App.vent, "survey:page:responses:error", (surveyId, errorCount) ->
        $('body').scrollTop(0)


      @show @layout

    addMultiResponseListeners: ->
      mySteps = App.request "flow:page:steps", @page
      mySteps.each (step) =>
        # add listeners that trigger response:set:error and response:set:success
        # for all steps on this page.
        @addSingleResponseListeners(App.request "response:get", step.get('id'))

    addSingleResponseListeners: (myResponse) ->
      @listenTo myResponse, "invalid", (responseModel) =>
        # response validation failed
        console.log "response invalid, errors are", responseModel.validationError
        App.vent.trigger "response:set:error", responseModel.validationError, @surveyId, responseModel.get('id')
      @listenTo myResponse, "change:response", (responseModel) =>
        # response validation succeeded
        if responseModel.get('response') isnt false
          # only trigger the response success event if the response isn't false.
          console.log "response correct, arg is", responseModel.get 'response'
          App.vent.trigger "response:set:success", responseModel.get('response'), @surveyId, responseModel.get('id')

    noticeRegion: ->
      App.execute "notice:region:set", @layout.noticeRegion

    progressRegion: ->
      # progress is based on the index of the current page's first step within the flow.
      progress = App.request 'flow:progress', @firstStep.get('id')
      progressView = @getProgressView progress

      @show progressView, region: @layout.progressRegion

    stepsLayoutRegion: ->

      switch @firstStep.get('type')
        when 'intro'
          # show the intro layout
          # TODO: Make this a special View, instead of just inserting the prompt in this region
          App.execute "steps:view:insert", @layout.stepsLayoutRegion, @surveyId, @firstStep.get('id')
        when 'beforeSurveySubmit'
          # show the beforeSurveySubmit layout
          # TODO: Make this a special View, instead of just inserting the prompt in this region
          App.execute "steps:view:insert", @layout.stepsLayoutRegion, @surveyId, @firstStep.get('id')
        when 'afterSurveySubmit'
          # show the afterSurveySubmit layout
          # TODO: Make this a special View, instead of just inserting the prompt in this region
          App.execute "steps:view:insert", @layout.stepsLayoutRegion, @surveyId, @firstStep.get('id')
        else
          console.log 'show a layout containing all prompts for this page'

          stepsView = @getStepsView App.request('flow:page:steps', @page)

          @listenTo stepsView, 'childview:render', (childView) =>
            # errorRegion - listens for global response:set:error that matches the stepId, updates itself if so
            # erases itself when the next button is pressed.
            childView.errorRegion.show @getStepErrorView(childView.model)

            if childView.model.get('skippable') is true
              # insert the step's skip view
              mySkipView = @getStepSkipView childView.model

              @listenTo mySkipView, "skipped", (stepId) =>
                App.vent.trigger "survey:step:skipped_displaying", stepId

              @listenTo mySkipView, "unskipped", (stepId) =>
                App.vent.trigger "survey:step:unskipped", stepId

              childView.skipButtonRegion.show mySkipView

            # insert the prompt stepBody view
            App.execute "steps:view:insert", childView.stepBodyRegion, @surveyId, childView.model.get('id')

          console.log 'set response validation listeners for this page'

          @show stepsView, region: @layout.stepsLayoutRegion

    prevButtonRegion: ->

      prevEntity = App.request "stepbutton:prev:entity", @firstStep.get('id')
      prevView = @getPrevButtonView prevEntity

      @listenTo prevView, "prev:clicked", =>
        @prevButtonAction()

      @listenTo App.vent, 'external:survey:prev:navigate', =>
        # Add external hook for navigating backwards in a survey
        @prevButtonAction()

      @show prevView, region: @layout.prevButtonRegion

    prevButtonAction: ->
      if @page is 1
        App.vent.trigger "survey:direct:prev:clicked", @surveyId, @page
      else
        switch @firstStep.get('type')
          when "intro", "beforeSurveySubmit", "afterSurveySubmit"
            App.vent.trigger "survey:direct:prev:clicked", @surveyId, @page
          else
            App.vent.trigger "survey:page:responses:get", @surveyId, @page, ( =>
              # success callback
              App.vent.trigger "survey:direct:prev:clicked", @surveyId, @page
            ),( (errorCount) =>
              # error callback
              myMessage = if errorCount is 1 then "This page contains an invalid or incomplete response. Going back will not save this invalid or incomplete response, continue?" else "This page contains #{errorCount} invalid or incomplete responses. Going back will not save any invalid or incomplete responses, continue?"
              App.execute "dialog:confirm", myMessage, (=>
                App.vent.trigger "survey:direct:prev:clicked", @surveyId, @page
              )
            )

    nextButtonRegion: ->

      nextEntity = App.request "stepbutton:next:entity", @firstStep.get('id')
      nextView = @getNextButtonView nextEntity

      @listenTo nextView, "next:clicked", =>
        console.log 'nextview listento next:clicked'

        switch @firstStep.get('type')
          when "intro"
            App.vent.trigger "survey:intro:next:clicked", @surveyId, @page
          when "beforeSurveySubmit"
            App.vent.trigger "survey:beforesubmit:next:clicked", @surveyId, @page
          when "afterSurveySubmit"
            App.vent.trigger "survey:aftersubmit:next:clicked", @surveyId, @page
          else
            App.vent.trigger "survey:page:responses:get", @surveyId, @page, ( =>
              # success callback
              App.vent.trigger "survey:prompts:next:clicked", @surveyId, @page
            ),( (errorCount) =>
              # error callback
              myDescription = if errorCount is 1 then "This page contains either an invalid or incomplete response. Please resolve before continuing." else "There are #{errorCount} invalid or incomplete responses on this page. Please resolve before continuing."

              App.execute "notice:show",
                data:
                  title: "Validation Error"
                  description: myDescription
                  showCancel: false
            )

      @show nextView, region: @layout.nextButtonRegion

    getProgressView: (progress) ->
      new Show.Progress
        model: progress

    getPrevButtonView: (prevStep) ->
      new Show.PrevButton
        model: prevStep

    getNextButtonView: (nextStep) ->
      new Show.NextButton
        model: nextStep

    getStepErrorView: (error) ->
      new Show.StepError
        model: error

    getStepSkipView: (skip) ->
      new Show.StepSkip
        model: skip

    getStepsView: (steps) ->
      new Show.Steps
        collection: steps

    getLayoutView: ->
      new Show.Layout
