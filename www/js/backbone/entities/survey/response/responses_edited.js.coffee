@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This handles edited responses for a Survey.

  API =
    getResponseDiff: (prepop_responses, responses) ->
      # compares prompt responses with edited prepop responses,
      # removes the responses that haven't changed.
      # Only filters photo, document, and video prompts.

