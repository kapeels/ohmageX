@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This handles History Media Queue operations on all items.
  # NOTE: This does not use oldLength and newLength like
  # the Upload Queue uses to count errors. Doing this was causing
  # strange errors when looping through the queue and
  # the queue item was returning null before it even got deleted.

  currentDeferred = []
  currentIndices = []

  API =
    downloadAll: (queue) ->
      console.log 'history media queue downloadAll'

      # map each item in the queue to a new Array,
      # containing Deferred objects.

      currentDeferred = []
      currentIndices = []

      currentDeferred = queue.map( (item, key) ->
        currentIndices.push(item.get 'id')
        return new $.Deferred()
      )

      $.when( currentDeferred... ).done =>
        @whenComplete()

      App.vent.trigger "history:media:queue:all:start"

      prevId = false

      queue.each (item, index) =>
        # when the previous id resolves, trigger the queue item

        if prevId
          prevIndex = currentIndices.indexOf(prevId)
          $.when(currentDeferred[prevIndex]).done => @triggerQueueItem item, index+1, queue.length
        prevId = item.get 'id'

      # trigger the first queue item to get the ball rolling
      @triggerQueueItem queue.at(0), 1, queue.length

    triggerQueueItem: (item, index, length) ->
      App.vent.trigger "loading:show", "Fetching history file #{index} of #{length}..."
      console.log "loading:show", "Fetching history file #{index} of #{length}..."
      itemId = item.get('id')
      context = item.get('context')

      if App.device.isNative
        App.execute "filemeta:fetch:auto", itemId, context
      else
        App.vent.trigger "filemeta:fetch:auto:success", itemId, context

    whenComplete: ->
      errorCount = App.request "history:media:queue:errors:count"
      myLength = App.request "history:media:queue:length"
      App.vent.trigger "history:media:queue:all:complete"
      if errorCount is 0
        # success, show success notice
        # App.execute "dialog:alert", "All History images and documents fetched successfully."
      else
        # some failed, use errorCount
        App.execute "dialog:alert", "Unable to fetch #{errorCount} out of #{myLength} images or documents in the History."

    queueFailure: (itemId, context) ->
      # the queue events - whether error or success -
      # must resolve each individual Deferred object.
      console.log "queue failure for #{itemId}"
      myIndex = currentIndices.indexOf(itemId)
      currentDeferred[myIndex].resolve()

    queueSuccess: (itemId) ->
      # the queue events - whether error or success -
      # must resolve each individual Deferred object.
      console.log "queue Success for #{itemId}"
      myIndex = currentIndices.indexOf(itemId)
      currentDeferred[myIndex].resolve()


  App.vent.on "history:entries:fetch:storage:success", ->
    if App.custom.functionality.history_auto_refresh and App.request("history:media:queue:length") > 0
      API.downloadAll App.request("history:media:queue")

  App.vent.on "filemeta:fetch:auto:success", (itemId) ->
    API.queueSuccess itemId

  App.vent.on "filemeta:fetch:auto:error", (itemId, context) ->
    API.queueFailure itemId, context
