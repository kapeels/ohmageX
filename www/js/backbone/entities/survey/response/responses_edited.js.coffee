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

