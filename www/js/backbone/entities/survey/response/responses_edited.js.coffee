@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This handles edited responses for a Survey.

  API =
    getResponseDiff: (prepop_responses, responses) ->
      # compares prompt responses with edited prepop responses,
      # removes the responses that haven't changed.
      # Only filters photo, document, and video prompts.

      responses.each (response) =>
        myId = response.get('id')
        myResponse = App.request "response:value:parsed",
          conditionValue: false
          stepId: myId
          addUploadUUIDs: false
          returnUUIDs: true

        if myResponse not in [false, 'SKIPPED', 'NOT_DISPLAYED'] and response.get('type') in ['photo', 'document', 'video']
          # only check submitted media prompts with valid responses,

          myPrepopUUID = prepop_responses.findWhere(stepId: myId).get('uuid')

          if response.get('type') is 'photo'
            # Check if our value is a base64. If it's not, we know it's a default file URL
            if myResponse.substring(0,10) isnt "data:image"
              removeIds.push(myId)
