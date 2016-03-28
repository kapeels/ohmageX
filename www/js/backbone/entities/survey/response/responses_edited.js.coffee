@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This handles edited responses for a Survey.

  API =
    getResponseDiff: (prepop_responses, responses) ->
      # compares prompt responses with edited prepop responses,
      # removes the responses that haven't changed.
      # Only filters photo, document, and video prompts.

      removeIds = []
      responses.each (response) =>
        myId = response.get('id')
        myResponse = App.request "response:value:parsed",
          conditionValue: false
          stepId: myId
          addUploadUUIDs: false
          returnUUIDs: true
        matchingPrepopResponse = prepop_responses.findWhere(stepId: myId)

        if myResponse not in [false, 'SKIPPED', 'NOT_DISPLAYED'] and response.get('type') in ['photo', 'document', 'video'] and typeof matchingPrepopResponse isnt "undefined"
          # only check submitted media prompts with valid responses, and only check when there's a matching
          # prepop response.

          myPrepopUUID = matchingPrepopResponse.get('uuid')

          console.log "****** myPrepopUUID", myPrepopUUID

          if response.get('type') is 'photo'
            # Check if our value is a base64. If it's not, we know it's a default file URL
            if myResponse.substring(0,10) isnt "data:image"
              removeIds.push(myId)
              console.log "***** it's a prepop photo"
            console.log "****** myResponse", myResponse
          else
            console.log "****** myId", myId

            console.log "****** myResponse", myResponse
            if myResponse is myPrepopUUID then removeIds.push myId

      console.log "****** removeIds", removeIds

      # remove all of our matching removeIds
      _.each removeIds, (removeId) => responses.remove responses.get(removeId)

      responses

  App.reqres.setHandler "responses:edited", ->
    API.getResponseDiff App.request("history:edit:prepop:responses"), App.request('responses:current')
