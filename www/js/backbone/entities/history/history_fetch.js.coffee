@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The HistoryFetch entity manages fetching data
  # for history items that are not part of the original history
  # entry request.

  API =
    fetchURL: (history_response, context) ->

      myData =
        client: App.client_string
        id: history_response.get 'prompt_response'

      myData = _.extend(myData, App.request("credentials:upload:params"))

      myURL = "#{App.request("serverpath:current")}/app/#{context}/read?#{$.param(myData)}"

      App.vent.trigger "history:response:fetch:#{context}:url", myURL, history_response

      myURL

    openExternalURL: (history_response) ->
      myURL = API.fetchURL history_response, "media"
      if App.device.isNative
        # open the URL in device external browser
        window.open myURL, '_system'
      else
        # open the URL in a new window
        window.open myURL, '_blank'

  App.commands.setHandler "history:response:fetch:image", (history_response) ->
    if App.device.isNative
      App.execute "filemeta:fetch:image:url", history_response.get('prompt_response')
    else
      API.fetchURL history_response, "image"

  App.commands.setHandler "history:response:fetch:media", (history_response) ->
    if App.device.isNative
      App.execute "filemeta:fetch:media:open", history_response.get('prompt_response')
    else
      API.openExternalURL history_response
