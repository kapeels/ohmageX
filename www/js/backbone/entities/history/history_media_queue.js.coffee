@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The HistoryMediaQueue is a queue for history media downloads.

  class Entities.HistoryMediaQueueItem extends Entities.Model
    defaults:
      fetched: false

  class Entities.HistoryMediaQueue extends Entities.Collection
    model: Entities.HistoryMediaQueueItem

  currentQueue = []

  API =
    init: ->
      currentQueue = new Entities.HistoryMediaQueue

    addQueue: (queue) ->
      currentQueue.add queue
      console.log 'history media queue', currentQueue.toJSON()
    getErrorCount: ->
      result = currentQueue.where(fetched: false) or []
      result.length

  App.on "before:start", ->
    API.init()

  App.commands.setHandler "history:media:queue:add", (queue) ->
    if queue.length > 0 then API.addQueue(queue)

  App.reqres.setHandler "history:media:queue", ->
    currentQueue

  App.reqres.setHandler "history:media:queue:length", ->
    currentQueue.length

  App.reqres.setHandler "history:media:queue:errors:count", ->
    API.getErrorCount()

  App.vent.on "filemeta:fetch:auto:success", (itemId) ->
    currentQueue.get(itemId).set 'fetched', true

  App.vent.on "history:fetch:start", ->
    API.init()
