@Ohmage.module "HistoryApp", (HistoryApp, App, Backbone, Marionette, $, _) ->

  class HistoryApp.Router extends Marionette.AppRouter
    before: ->
      if !App.request("credentials:isloggedin")
        App.navigate Routes.default_route(), trigger: true
        return false
    appRoutes:
      "history": "list"
      "history/group/:group": "bucket"
      "history/entry/:id": "entry"

  API =
    list: ->
      App.vent.trigger "nav:choose", "history"
      console.log 'HistoryApp list'
      new HistoryApp.List.Controller
        buckets_filter: false

    bucket: (bucket) ->
      App.vent.trigger "nav:choose", "history"
      console.log 'HistoryApp bucket'
      new HistoryApp.List.Controller
        buckets_filter: bucket

    entry: (id) ->
      if App.navs.getSelectedName() isnt "history"
        App.vent.trigger "nav:choose", "history"
      new HistoryApp.Entry.Controller
        entry_id: id

  App.addInitializer ->
    new HistoryApp.Router
      controller: API

  App.vent.on "history:entries:fetch:error history:entries:fetch:success", ->
    App.vent.trigger "loading:hide"

  App.vent.on "history:list:entry:clicked", (myId) ->
    API.entry myId
    App.navigate "history/entry/#{myId}"

  App.vent.on "history:entry:delete:clicked", (model) ->
    App.execute "notice:show",
      data:
        title: "Delete Responses"
        description: "Are you sure you want to delete this #{App.dictionary('page','survey')}? Select OK to proceed."
        showCancel: true
      okListener: =>
        App.vent.trigger "loading:show", "Deleting..."
        App.execute "history:entry:remove", model

  App.vent.on "history:entry:remove:error", (entry, errorText) ->
    App.execute "dialog:alert", errorText

  App.vent.on "history:entry:remove:success history:entry:remove:error history:media:queue:all:complete", ->
    App.vent.trigger "loading:hide"

  App.vent.on "history:media:queue:all:start", ->
    App.vent.trigger "loading:show", "Fetching History images and documents..."

  App.vent.on "file:media:open:error", ->
    App.execute "dialog:alert", "Unable to open document or video."

  App.vent.on "history:entry:fetch:image:clicked", (response) ->
    App.execute "history:response:fetch:image", response

  App.vent.on "history:entry:fetch:media:clicked", (response) ->
    App.execute "history:response:fetch:media", response

  App.vent.on "file:media:open:complete file:media:open:error file:image:url:success file:image:url:error", ->
    App.vent.trigger "loading:hide"

  App.vent.on "history:entry:fullmodal:close", ->
    # Since this came from a modal view,
    # there is the chance that the modal was navigated to DIRECTLY.
    # if this was the case, the app mainRegion would be empty.
    # We can detect this and render the history list appropriately.
    options = if typeof App.mainRegion.currentView is "undefined" then {trigger: true} else {}
    App.navigate "history", options
