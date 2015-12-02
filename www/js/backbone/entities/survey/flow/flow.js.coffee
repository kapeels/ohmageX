@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The Flow Entity contains data related to the flow
  # of the Steps within a Survey.
  # This module contains the initialization for Flow.

  # currentFlow
  # "flow:init" initializes a StepCollection that persists in memory.
  # This collection is removed with "flow:destroy"
  currentFlow = false

  class Entities.Step extends Entities.Model
    defaults: # default values for all Steps:
      condition: true # Step is always shown
      entity: false # entity is not initialized
      skippable: false # Step can't be skipped
      skiplabel: false # Skip label is empty
      status: "pending" # Step hasn't been processed
      page: false # no page assigned to this step

  class Entities.StepCollection extends Entities.Collection
    model: Entities.Step

  API =
    init: ($surveyXML) ->
      throw new Error "flow already initialized, use 'flow:destroy' to remove existing flow" unless currentFlow is false
      currentFlow = new Entities.StepCollection
      $root = App.request("survey:xml:root", $surveyXML)
      myIntroStep = @createIntroStep $root
      currentFlow.add myIntroStep
      myContentSteps = @createContentSteps App.request("survey:xml:content", $surveyXML)
      currentFlow.add myContentSteps
      mySurveySubmitSteps = @createSurveySubmitSteps $root
      currentFlow.add mySurveySubmitSteps
      console.log 'Current flow Object', currentFlow.toJSON()
      App.vent.trigger "flow:init:complete", currentFlow
    getFlow: ->
      throw new Error "flow not initialized, use 'flow:init' to create new Flow" unless currentFlow isnt false
      currentFlow

    createIntroStep: ($rootXML) ->

      # Only show this Step if the introText tag exists and it's not false.
      introCondition = !!$rootXML.find('introText').length and $rootXML.tagText('introText') isnt "false"

      result =
        id: "#{$rootXML.tagText('id')}Intro"
        type: "intro"
        condition: introCondition
        status: if introCondition then "displayed" else "not_displayed"
        $XML: $rootXML

    createContentSteps: ($contentXML) ->
      _.map( $contentXML.children(), (child) ->
        $child = $(child)

        isMessage = $child.prop('tagName') is 'message'
        conditionExists = !!$child.find('condition').length
        mySkipLabel = if !!$child.find('skipLabel').length then $child.tagText('skipLabel') else false

        result =
          id: $child.tagText('id')
          type: if isMessage then "message" else $child.tagText('promptType')
          condition: if conditionExists then $child.tagText('condition') else true
          $XML: $child
          skippable: $child.tagText('skippable') is "true"
          skiplabel: mySkipLabel
          meta: App.request('xmlmeta:xml:to:json', $child.tagHTML(App.xmlMeta.rootLabel))
      )

    createSurveySubmitSteps: ($rootXML) ->
      result = []
      result.push
        id: "#{$rootXML.tagText('id')}beforeSurveySubmit"
        type: "beforeSurveySubmit"
        $XML: $rootXML

      result.push
        id: "#{$rootXML.tagText('id')}afterSurveySubmit"
        type: "afterSurveySubmit"
        $XML: $rootXML

      result
    destroyFlow: ->
      currentFlow = false

  App.commands.setHandler "flow:init", ($surveyXML) ->
    API.init $surveyXML

  App.reqres.setHandler "flow:init:status", ->
    currentFlow isnt false

  App.reqres.setHandler "flow:current", ->
    API.getFlow()

  App.reqres.setHandler "flow:step", (id) ->
    currentFlow = API.getFlow()
    myStep = currentFlow.get(id)
    throw new Error "step id #{id} does not exist in currentFlow" if typeof myStep is 'undefined'
    myStep

  App.vent.on "survey:exit survey:reset", ->
    API.destroyFlow()
