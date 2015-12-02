@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The Response Entity contains data related to the responses
  # within a given Survey.
  # This module contains the handlers that update a response.

  # currentResponses
  # References the current Response ResponseCollection object, defined in response.js.coffee
  # via the interface "responses:current"

  API =
    updateResponse: (options) ->
      { myResponse, newValue, validate } = options
      console.log 'myResponse set validate', validate
      if newValue
        myResponse.set {response: newValue }, { validate: validate }
      # if newValue is false, leave
      # the response value alone.

      # console.log 'myResponse', myResponse.toJSON()

  App.commands.setHandler "response:set", (newValue, stepId) ->
    API.updateResponse
      myResponse: App.request "response:get", stepId
      newValue: newValue
      validate: true
