@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The survey tracker Entity tracks whether
  # the user is currently engaged in a survey or not.
  # it also tracks the currently viewed Page of the survey,
  # if using the multi-question view.

  currentStatus = false
  currentPage = false

  API =
    setActive: ->
      currentStatus = true
    setInactive: ->
      currentStatus = false
    startPages: ->
      currentPage = 1
    endPages: ->
      currentPage = false

  App.reqres.setHandler "surveytracker:active", ->
    currentStatus

  App.reqres.setHandler "surveytracker:page", ->
    currentPage

  App.commands.setHandler "surveytracker:page:set", (page) ->
    currentPage = parseInt(page)

    App.vent.trigger "surveytracker:page:new", currentPage

  App.reqres.setHandler "surveytracker:page:previous", ->
    if currentPage is 1 then throw new Error "Attempting to go to previous page when currentPage is already 1"
    App.vent.trigger "surveytracker:page:old", currentPage
    currentPage-1

  App.reqres.setHandler "surveytracker:page:next", ->
    currentPage+1

  App.vent.on "survey:start", (surveyId) ->
    API.setActive()
    API.startPages()
    $('body').addClass('survey-active')

  App.vent.on "survey:exit survey:reset credentials:cleared", (surveyId) ->
    $('body').removeClass('survey-active')
    API.setInactive()
    API.endPages()
