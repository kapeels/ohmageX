@Ohmage.module "Components.Navbutton", (Navbutton, App, Backbone, Marionette, $, _) ->

  # This Navbutton Selector returns a specific view, based on the
  # currently selected Nav button

  class Navbutton.SelectorController extends App.Controllers.Application
    initialize: (options) ->
      { navs, selected } = options

      @myView = @selectView navs, selected

      if @myView
        @listenTo @myView, "button:history", (type) ->
          console.log "button:history in Navbutton Component"
          App.execute "history:sync"

        @listenTo @myView, "button:sync", (type) ->
          console.log "button:sync in Navbutton Component"
          App.execute "campaigns:sync"

        @listenTo @myView, "button:upload", (type) ->
          console.log "button:upload in Navbutton Component"
          App.execute "uploadqueue:upload:all"

        @listenTo @myView, "button:add:reminder", (type) ->
          console.log "button:add:reminder in Navbutton Component"
          App.execute "reminders:add:new"

        # Ensure this controller is removed during view cleanup.
        @listenTo @myView, "destroy", @destroy

    selectView: (navs, selected) ->
      switch selected
        when "campaign"
          return new Navbutton.Sync
            collection: navs
        when "queue"
          return new Navbutton.Upload
            collection: navs
        when "history", "dashboardeqis"
          return new Navbutton.History
            collection: navs
        when "reminder"
          return new Navbutton.AddReminder
            collection: navs
        else
          return false

  App.reqres.setHandler "navbuttons:view", (navs) ->
    window.navs = navs
    selected = navs.findWhere({ chosen: true }).get('name')

    selector = new Navbutton.SelectorController
      navs: navs
      selected: selected

    selector.myView
