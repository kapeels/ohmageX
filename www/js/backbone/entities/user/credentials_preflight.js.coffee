@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # the credentials preflight entity handles all pre-flight credentials
  # checks.

  API =
    isParsedAuthValid: (response) ->
      # if there's a failure that's not auth-related,
      # try the result and let its error handlers deal with it.
      !(response.result is "failure" and response.errors[0].code in ['0200','0201','0202'])

    preflightCheck: (path, callback) ->
      App.vent.trigger "loading:show", "Loading..."

      myData =
        client: App.client_string
        start_date: moment().format("YYYY-MM-DD")
        end_date: moment().format("YYYY-MM-DD")
        output_format: "short"

      $.ajax
        type: "POST"
        url: "#{path}/app/campaign/read"
        data: _.extend(myData, App.request("credentials:upload:params"))
        dataType: 'json'
        success: (response) =>
          App.vent.trigger "loading:hide"
          if @isParsedAuthValid response
            callback()
          else
            @showBlocker callback

        error: =>
          App.vent.trigger "loading:hide"
          # network error of some kind. Try the result and
          # let its error handlers deal with the network issue.
          callback()

    showBlocker: (callback) ->
      App.vent.trigger 'blocker:password:invalid',
        successListener: callback

  App.commands.setHandler 'credentials:preflight:check', (callback) ->
    if App.request "credentials:ispassword"
      API.preflightCheck App.request("serverpath:current"), callback
    else
      # just execute the callback if using tokens. An auth failure will trigger
      # a token redirect instead.
      callback()

  App.vent.on "surveys:saved:campaign:fetch:failure:auth campaigns:sync:failure:auth", (errorText) ->
    API.showBlocker (->
      App.execute "dialog:alert", "Password validated."
    )

  App.vent.on "uploadqueue:upload:failure:auth", (responseData, errorText, surveyId) ->
    API.showBlocker (->
      App.execute "dialog:alert", "Password validated."
    )
