@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # controls surveys scroll position used in
  # the surveys_multi module.

  API =
    geteQISScrollPosition: ->
      # hard code the scroll position
      350

  App.reqres.setHandler "surveys:scroll:position", (survey_id, page) ->
    if App.custom.functionality.history_eqis_bucketing isnt false and # e-QIS first response bucketing is enabled
        page is 1 and # only on the first page
        !App.request("flow:prepop:is:empty") and # the survey contains prepopulated responses
        App.request("survey:saved:server_id", survey_id) in App.custom.functionality.history_eqis_bucketing.firstresponse_surveyids # the survey is one of the firstresponse bucketed surveys
      API.geteQISScrollPosition()
    else
      0
