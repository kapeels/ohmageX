@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This deals with the Upload All action events.

  currentDeferred = []
  currentIndices = []

  API =
    uploadAll: (queue) ->
      console.log "uploadqueue uploadAll"
      # save current queue length.
      oldLength = queue.length
      # map each item in the queue to a new Array,
      # containing Deferred objects.

      currentDeferred = []
      currentIndices = []

      currentDeferred = queue.map( (item, key) ->
        currentIndices.push(item.get 'id')
        return new $.Deferred()
      )

      # tracking indices in a separate array.
      # Required if using Coffeescript splats to pass
      # arguments to Deferred (which map to .apply())
      # can't use an "associative" array
      $.when( currentDeferred... ).done =>
        @whenComplete(oldLength)

      # Fire an upload event for ALL of the items in the queue.
      # note the 'uqall' event prefix.
      queue.each( (item) ->
        App.execute "uploader:new", 'uqall', item.get('data'), item.get('id')
      )

    whenComplete: (oldLength) ->
      newLength = App.request 'uploadqueue:length'
      App.vent.trigger "uploadqueue:all:complete"
      console.log "whenComplete queue", newLength
      if newLength is 0
        # success, show success notice
        App.execute "notice:show",
          data:
            title: "Upload Success"
            description: "All responses uploaded successfully."
            showCancel: false
      else
        # some failed, use oldLength
        App.execute "notice:show",
          data:
            title: "Upload Failure"
            description: "#{newLength} out of #{oldLength} responses failed to upload."
            showCancel: false

    queueFailureGeneral: (errorPrefix, errorText, itemId) ->
      App.execute "uploadqueue:item:error:set", itemId, "#{errorPrefix} #{errorText}"
      # the uqall events - whether error or success -
      # must resolve each individual Deferred object.
      myIndex = currentIndices.indexOf(itemId)
      currentDeferred[myIndex].resolve()

    queueSuccess: (itemId) ->
      App.execute "uploadqueue:item:remove", itemId
      # the uqall events - whether error or success -
      # must resolve each individual Deferred object.
      myIndex = currentIndices.indexOf(itemId)
      currentDeferred[myIndex].resolve()


  App.commands.setHandler "uploadqueue:upload:all", ->
    queue = App.request 'uploadqueue:entity'

    if queue.length > 0
      API.uploadAll queue

  App.vent.on "uqall:upload:success", (response, itemId) ->
    API.queueSuccess itemId

  App.vent.on "uqall:upload:failure:campaign", (responseData, errorText, itemId) ->
    API.queueFailureGeneral "Problem with Survey Campaign:", errorText, itemId

  App.vent.on "uqall:upload:failure:response", (responseData, errorText, itemId) ->
    # placeholder for response errors handler.
    API.queueFailureGeneral "Problem with Survey Response:", errorText, itemId

  App.vent.on "uqall:upload:failure:server", (responseData, errorText, itemId) ->
    # placeholder for server errors handler.
    API.queueFailureGeneral "Problem with Server:", errorText, itemId

  App.vent.on "uqall:upload:failure:auth", (responseData, errorText, itemId) ->
    # placeholder for auth errors handler.
    API.queueFailureGeneral "Problem with Auth:", errorText, itemId

  App.vent.on "uqall:upload:failure:network", (responseData, errorText, itemId) ->
    # placeholder for network errors handler.
    API.queueFailureGeneral "Problem with Network:", errorText, itemId

  App.vent.on "uqall:upload:failure:wifionly", (responseData, errorText, itemId) ->
    API.queueFailureGeneral "Cannot Upload:", "User preferences set to only upload on wifi.", itemId
