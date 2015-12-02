@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The Response Entity contains data related to the responses
  # within a given Survey.
  # This module contains the handlers that parse a response.

  # currentResponses
  # References the current Response ResponseCollection object, defined in response.js.coffee
  # via the interface "responses:current"

  API = 
    parseInvalidToValue: (myStatus, responseValue, stepId) ->
      # convert invalid responses (such as false or incomplete)
      # into equivalents required by the server,
      # based on the flow status of the step.

      switch myStatus
        when 'pending','displaying','skipped_displaying'
          return false
        when 'skipped'
          return 'SKIPPED'
        when 'not_displayed'
          return 'NOT_DISPLAYED'
        when 'hidden'
          # hidden prompts return the actual response value.
          # We currently assume that hidden prompts are number prompts only.
          return responseValue
        else
          throw new Error "invalid response for step #{stepId} with invalid flow status: #{myStatus}"

    parseValueByType: (options) ->
      _.defaults options,
        conditionValue: false
        # condition value returns a value optimized for conditional parsing
        # instead of the survey upload value.

      { responseValue, type, addUploadUUIDs, conditionValue } = options

      switch type
        when 'single_choice'
          return responseValue.key
        when 'single_choice_custom'
          if conditionValue
            return responseValue.key
          else
            return responseValue.label
        when 'multi_choice'
          if conditionValue
            return responseValue.keys
          else
            return JSON.stringify responseValue.keys
        when 'multi_choice_custom'
          if conditionValue
            return responseValue.keys
          else
            return JSON.stringify responseValue.labels
        when 'timestamp'
          # because timestamp responses are raw strings,
          # even though they have been tested with the validator, they
          # have not been saved in the required ISO format, and
          # must be parsed.
          m = moment(responseValue)
          return m.format()
        when 'photo'
          # photo responses must reference a UUID, not the base64.
          # base64 are submitted with a separate parameter `images`
          # which is generated from the survey_upload_images entity.

          # we only want to add and create Image UUIDs in special
          # circumstances, such as survey upload.
          if !addUploadUUIDs then return responseValue

          App.execute "survey:images:add", responseValue
          return App.request "survey:images:uuid:last"
        when 'document'
          # document prompts must return different values,
          # depending on whether the document was generated in a
          # native context or a browser context.

          # The value of a file is its UUID before uploading.
          # these will later get attached to the response object as separate properties.

          # we only want to add and create File UUIDs in special
          # circumstances, such as survey upload.
          if !addUploadUUIDs then return responseValue.fileName

          App.execute "survey:file:add", responseValue
          return responseValue.UUID
        when 'video'
          # video prompts must return different values,
          # depending on the video's source type.

          # The value of a file is its UUID before uploading.
          # these will later get attached to the response object as separate properties.

          # we only want to add and create File UUIDs in special
          # circumstances, such as survey upload.
          if !addUploadUUIDs then return responseValue.videoName

          App.execute "survey:file:add", responseValue
          return responseValue.UUID

        else
          return responseValue

    parseValue: (options) ->
      { stepId, myResponse, addUploadUUIDs, conditionValue } = options

      if App.request("flow:status", stepId) is 'complete'
        return @parseValueByType
          responseValue: myResponse.get 'response'
          type: myResponse.get 'type'
          addUploadUUIDs: addUploadUUIDs
          conditionValue: conditionValue
      else
        return @parseInvalidToValue App.request("flow:status", stepId), myResponse.get('response'), options.stepId

  App.reqres.setHandler "response:value:parsed", (options) ->
    options.myResponse = App.request "response:get", options.stepId
    API.parseValue options
