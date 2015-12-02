@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # HistoryResponses manages responses returned from a single
  # history Entry.

  class Entities.UserHistoryResponse extends Entities.Model
    defaults:
      media_url: false

  class Entities.UserHistoryResponses extends Entities.Collection
    model: Entities.UserHistoryResponse
    initialize: ->
      @listenTo App.vent, 'history:response:fetch:image:url history:response:fetch:media:url', (myURL, entry) ->
        if @findWhere(id: entry.get('id'))
          @findWhere(id: entry.get('id')).set('media_url', myURL)

      @listenTo App.vent, "file:image:url:success", (uuid, url) ->
        if @findWhere(prompt_response: uuid)
          @findWhere(prompt_response: uuid).set('media_url', url)

      @listenTo App.vent, "file:image:url:error", (uuid) ->
        if @findWhere(prompt_response: uuid)
          @findWhere(prompt_response: uuid).set('media_url', false)

  API =
    getResponses: (rawResponses) ->
      new Entities.UserHistoryResponses rawResponses

  App.reqres.setHandler "history:entry:responses", (id) ->
    API.getResponses App.request("history:entry:responses:raw", id)
