@Ohmage.module "CampaignsApp", (CampaignsApp, App, Backbone, Marionette, $, _) ->

  class CampaignsApp.Router extends Marionette.AppRouter
    before: ->
      if !App.request("credentials:isloggedin")
        App.navigate Routes.default_route(), trigger: true
        return false
    appRoutes:
      "campaigns": "list"

  API =
    list: ->
      App.vent.trigger "nav:choose", "campaign"
      new CampaignsApp.List.Controller

  App.addInitializer ->
    new CampaignsApp.Router
      controller: API

  App.vent.on "campaign:list:navigate:clicked", (model) ->
    if App.custom.routes.surveys is "survey"
      App.navigate "surveys/#{model.get 'id'}", { trigger: true }
    else
      App.navigate App.navs.getUrlByName(App.custom.routes.surveys), { trigger: true }

  App.vent.on "campaign:list:save:clicked", (model) ->
    # the campaign:save command handler is in the Surveys entity.
    # it does not manage the display of the loader so other parts
    # of the app can use it.
    App.vent.trigger "loading:show", "Saving #{App.dictionary('page','campaign')}..."

    App.execute "campaign:save", model

  App.vent.on "campaign:list:unsave:clicked", (model, view, filterType) ->
    if App.request("user:metadata:has:campaign", model.get('id'))
      App.execute "dialog:confirm", "Are you sure you want to unsave this #{App.dictionary('page','campaign')}? You have saved data for it.", (=>
        App.execute "campaign:unsave", model.get 'id'
        if filterType is 'saved' then view.destroy()
      )
    else
      App.execute "campaign:unsave", model.get 'id'
      if filterType is 'saved' then view.destroy()

  App.vent.on "campaign:list:ghost:remove:clicked", (model) ->
    console.log 'model', model
    App.execute "campaign:ghost:remove", model.get('id'), model.get('status')
