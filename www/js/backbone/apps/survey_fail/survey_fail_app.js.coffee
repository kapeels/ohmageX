@Ohmage.module "SurveyFailApp", (SurveyFailApp, App, Backbone, Marionette, $, _) ->

  # All survey upload failure handlers are consolidated in this module.

  API =
    uploadFailureGeneral: (responseData, errorPrefix, errorText, surveyId) ->
      # show notice to let them retry.
      console.log 'survey:upload:failure:campaign'

      App.execute "notice:show",
        data:
          title: "Unable to Upload #{App.dictionary('page','survey').capitalizeFirstLetter()}"
          description: "#{errorPrefix} #{errorText} - Retry or select OK to save the #{App.dictionary('page','survey')} to the Upload Queue."
          showCancel: true
          cancelLabel: "Ok"
          okLabel: "Retry"
        cancelListener: =>
          # After Queue implemented: Put the survey item in the upload queue.
          console.log 'responseData in cancelListener', responseData
          App.execute "uploadqueue:item:add", responseData, "#{errorPrefix} #{errorText}", surveyId
          # After Notice Center: Notify the user that the item was put into their upload queue.

          # Broadcast that the user selected OK after the failure happened.
          App.vent.trigger "survey:upload:failure:ok", responseData, surveyId
        okListener: =>
          App.execute "survey:upload", surveyId

  App.vent.on "survey:upload:failure:campaign", (responseData, errorText, surveyId) ->
    console.log responseData
    API.uploadFailureGeneral responseData, "Problem with #{App.dictionary('page','survey')} #{App.dictionary('page','campaign')}:", errorText, surveyId

  App.vent.on "survey:upload:failure:response", (responseData, errorText, surveyId) ->
    # placeholder for response errors handler.
    console.log responseData
    API.uploadFailureGeneral responseData, "Problem with #{App.dictionary('page','survey')} Response:", errorText, surveyId

  App.vent.on "survey:upload:failure:server", (responseData, errorText, surveyId) ->
    # placeholder for server errors handler.
    API.uploadFailureGeneral responseData, "Problem with Server:", errorText, surveyId

  App.vent.on "survey:upload:failure:abort", (responseData, errorText, surveyId) ->
    # placeholder for server errors handler.
    API.uploadFailureGeneral responseData, "#{App.dictionary('page','survey').capitalizeFirstLetter()} upload aborted:", errorText, surveyId

  App.vent.on "survey:upload:failure:auth", (responseData, errorText, surveyId) ->
    # placeholder for auth errors handler.
    API.uploadFailureGeneral responseData, "Problem with Auth:", errorText, surveyId

  App.vent.on "survey:upload:failure:network", (responseData, errorText, surveyId) ->
    # placeholder for network errors handler.
    API.uploadFailureGeneral responseData, "", "Network Error", surveyId

  App.vent.on "survey:upload:failure:wifionly", (responseData, errorText, surveyId) ->
    API.uploadFailureGeneral responseData, "Cannot Upload: ", "User preferences set to only upload on wifi.", surveyId
