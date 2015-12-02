@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This queue handles all responses on a given page.

  currentDeferred = []
  currentIndices = []
  errorCount = 0

  API =
    validateAll: (queue, surveyId, successCallback, errorCallback) ->
      console.log 'response page queue validateAll'

      currentDeferred = []
      currentIndices = []
      errorCount = 0

      currentDeferred = queue.map( (item, key) ->
        currentIndices.push(item.get 'id')
        return new $.Deferred()
      )

      # tracking indices in a separate array.
      # Required if using Coffeescript splats to pass
      # arguments to Deferred (which map to .apply())
      # can't use an "associative" array
      $.when( currentDeferred... ).done =>
        @whenComplete surveyId, successCallback, errorCallback

      # Fire a validation event for ALL of the responses in the queue.
      queue.each( (item) =>
        if item.get('status') is 'skipped_displaying' or item.get('type') is 'message'
          # don't validate any skipped_displaying items, just assume success
          # same with message prompts
          @itemSuccess(item.get('id'))
        else
          App.vent.trigger "survey:response:get", surveyId, item.get('id')
      )


    whenComplete: (surveyId, successCallback, errorCallback) ->
      console.log 'errorCount', errorCount
      App.vent.trigger "survey:page:responses:complete", errorCount

      if errorCount is 0
        App.vent.trigger "survey:page:responses:success", surveyId
        successCallback()
      else
        # some responses contained errors
        App.vent.trigger "survey:page:responses:error", surveyId, errorCount
        errorCallback errorCount

    itemError: (itemId) ->
      errorCount++
      myIndex = currentIndices.indexOf(itemId)
      currentDeferred[myIndex].resolve()

    itemSuccess: (itemId) ->
      myIndex = currentIndices.indexOf(itemId)
      currentDeferred[myIndex].resolve()

  App.vent.on "survey:page:responses:get", (surveyId, page, successCallback, errorCallback) ->
    API.validateAll App.request('flow:page:steps', page), surveyId, successCallback, errorCallback

  App.on "before:start", ->

    if App.custom.functionality.multi_question_survey_flow is true
      App.vent.on "response:set:error", (error, surveyId, stepId) ->
        API.itemError stepId

      App.vent.on "response:set:success", (response, surveyId, stepId) ->
        API.itemSuccess stepId
