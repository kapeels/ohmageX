@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The Surveys Category Entity handles surveys
  # that match specific custom categories.

  API =
    getCategorySurveys: (surveys, category) ->
      surveys = surveys.filter (survey) =>
        category_meta = survey.get('parent_meta').categorykey[0]._text
        category_meta is category

      new Entities.SurveysSaved surveys


  App.reqres.setHandler "surveys:saved:category", (category) ->
    API.getCategorySurveys App.request("surveys:saved"), category
