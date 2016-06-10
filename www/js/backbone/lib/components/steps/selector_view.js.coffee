@Ohmage.module "Components.Steps", (Steps, App, Backbone, Marionette, $, _) ->

  class Steps.Intro extends App.Views.ItemView
    className: "text-container"
    template: "steps/intro"
    serializeData: ->
      data = @model.toJSON()
      console.log 'Steps.Intro data', data
      data

  class Steps.Message extends App.Views.ItemView
    className: "step-message"
    template: "steps/message"
    openLink: (e) ->
      e.preventDefault()
      targetHref = $(e.currentTarget).attr('href')
      console.log "openLink to #{targetHref}"

      if App.device.isNative
        console.log 'targetHref' + targetHref
        targetLocation = if device.platform is "Android" then '_system' else '_blank'
        console.log 'targetLocation', targetLocation
        cordova.InAppBrowser.open targetHref, targetLocation, '' #, 'toolbar=no'
      else
        window.open targetHref, '_blank'

    serializeData: ->
      data = @model.toJSON()
      console.log 'Steps.Message data', data
      data

    events: ->
      # Any prompts that extend this base prompt must take
      # into account this `events` property, otherwise they
      # could easily overwrite the `events`.

      if App.device.isNative
        "touchstart a": "openLink"
      else
        "click a": "openLink"


  class Steps.BeforeSubmission extends App.Views.ItemView
    className: "text-container"
    template: "steps/beforesubmission"
    serializeData: ->
      data = @model.toJSON()
      console.log 'Steps.BeforeSubmission data', data
      # Disable the 'automatic survey upload' that made this step a Loading step
      # data.completeTitle = 'Uploading Survey'
      data.completeTitle = "#{App.dictionary('page', 'survey').capitalizeFirstLetter()} Submit"
      data

  class Steps.AfterNoReminders extends App.Views.ItemView
    className: "text-container"
    template: "steps/after_noreminders"
    triggers:
      "click .reminder-create": "new:reminder"

  class Steps.ReminderTime extends App.Views.ItemView
    tagName: "li"
    template: "steps/_remindertime"
    serializeData: ->
      data = @model.toJSON()
      console.log 'Steps.ReminderTime data', data
      data.timestamp = @model.get('activationDate').format("h:mm a")
      data
    onRender: ->
      deleteByDefault = true
      if deleteByDefault then @$el.find("input").prop('checked', true)

  class Steps.AfterSuppressReminders extends App.Views.CompositeView
    initialize: ->
      @listenTo @, "submit:notifications", @gatherIds
    gatherIds: ->
      # loop through all reminder input boxes. create an array of
      # all the selected values and return that.
      notificationIds = _.map @$el.find('input:checked'), (myInput) ->
        return $(myInput).val()
      if notificationIds.length > 0
        @collection.trigger("suppress", notificationIds)
        @trigger "suppress:notifications", notificationIds
    className: "text-container"
    template: "steps/after_suppressreminders"
    childView: Steps.ReminderTime
    childViewContainer: ".reminder-times"
    triggers:
      "click .reminder-suppress": "submit:notifications"


  class Steps.AfterSubmission extends App.Views.ItemView
    className: "text-container"
    template: "steps/aftersubmission"
    serializeData: ->
      data = @model.toJSON()
      console.log 'Steps.AfterSubmission data', data
      data.completeTitle = "#{App.dictionary('page','survey').capitalizeFirstLetter()} Complete"
      data.summary = "#{App.dictionary('page','survey').capitalizeFirstLetter()} successfully uploaded or stored in the #{App.dictionary('page','queue')}."
      data
