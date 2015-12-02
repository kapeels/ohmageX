@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The StepButton Entity generates entities for the custom 
  # StepButton views.

  class Entities.StepButtonSkip extends Entities.Model
    defaults: # default values for all StepButtonSkips
      disabled: true # disable all by default
      label: "Skip"

  class Entities.StepButtonPrev extends Entities.Model
    defaults: # default values for all StepButtonPrevs
      disabled: false # enable all by default
      label: "Back"

  class Entities.StepButtonNext extends Entities.Model
    defaults: # default values for all StepButtonNexts
      label: "Next" # enable all by default

  API =
    skipEntity: (currentStep) ->

      new Entities.StepButtonSkip
        disabled: !currentStep.get 'skippable'
        label: currentStep.get 'skipLabel'

    prevEntity: (stepType, stepId) ->
      # Disable the 'automatic survey upload' that made this step a Loading step
      # disabled = stepType in ["intro", "beforeSurveySubmit", "afterSurveySubmit"]
      disabled = stepType in ["intro", "afterSurveySubmit"]

      new Entities.StepButtonPrev
        disabled: disabled

    nextEntity: (stepType, stepId) ->
      myLabel = switch stepType
        when "intro" then "Begin Survey"
        when "beforeSurveySubmit" then "Submit"
        when "afterSurveySubmit" then "Done"
        else "Next"

      new Entities.StepButtonNext
        label: myLabel

  App.reqres.setHandler "stepbutton:skip:entity", (stepId) ->
    currentStep = App.request "flow:step", stepId
    API.skipEntity currentStep

  App.reqres.setHandler "stepbutton:prev:entity", (stepId) ->
    stepType = App.request "flow:type", stepId
    API.prevEntity stepType, stepId

  App.reqres.setHandler "stepbutton:next:entity", (stepId) ->
    stepType = App.request "flow:type", stepId
    API.nextEntity stepType, stepId
