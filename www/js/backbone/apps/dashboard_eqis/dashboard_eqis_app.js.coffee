@Ohmage.module "DashboardeQISApp", (DashboardeQISApp, App, Backbone, Marionette, $, _) ->

  class DashboardeQISApp.Router extends Marionette.AppRouter
    before: ->
      if !App.request("credentials:isloggedin")
        App.navigate Routes.default_route(), trigger: true
        return false
    appRoutes:
      "dashboard": "show"

  API =
    show: (id) ->
      App.vent.trigger "nav:choose", "dashboardeqis"
      console.log 'DashboardeQISApp show'
      new DashboardeQISApp.Show.Controller

  App.addInitializer ->
    new DashboardeQISApp.Router
      controller: API

  App.vent.on "dashboardeqis:responsecount:clicked", (bucket) ->
    App.navigate "history/group/#{bucket}", trigger: true

  App.vent.on "dashboardeqis:newsurvey:clicked", (campaign_urn, surveyId, newPrepopIndex, newPrepopStep) ->
    if newPrepopIndex isnt false
      App.execute "flow:prepop:add", newPrepopStep, newPrepopIndex

    App.navigate "survey/#{campaign_urn}:#{surveyId}", trigger: true
