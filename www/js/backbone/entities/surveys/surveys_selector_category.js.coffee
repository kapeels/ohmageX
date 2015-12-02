@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The surveys selector creates categories for the Campaign Chooser.

  class Entities.SurveysCategory extends Entities.Nav
    initialize: (options) ->
      # map categories into our version of this list
      console.log 'SurveysCategory initialize'
      if options.name isnt 'All'
        console.log 'isnt all'
        @set { name: options.name, url: "#surveys/category/#{options.id}" }

  class Entities.SurveysCategories extends Entities.NavsCollection
    model: Entities.SurveysCategory
    chooseById: (nav) ->
      # we expect chosen to be false if no category is selected,
      # it chooses the first (default) item in the list if this is the case
      @choose (@findWhere(id: nav) or @first())

  API =
    getNavs: (saved, chosen) ->
      # Ensure All link is prepended to the list.
      navs = new Entities.SurveysCategories [{ name: 'All', url: "#surveys" }]
      # add hardcoded categories into this list here.
      navs.add [
        {
          name: 'Assessments'
          id: 'assessments'
        },
        {
          name: 'Recipes'
          id: 'recipes'
        }
      ]
      navs.chooseById(chosen)
      navs

  App.reqres.setHandler "surveys:selector:category", (chosen) ->
    saved = App.request "campaigns:saved:current"
    API.getNavs saved, chosen
