
@Ohmage.module "RemindersApp.List", (List, App, Backbone, Marionette, $, _) ->

  # RemindersApp renders the Reminders page.

  class List.Controller extends App.Controllers.Application
    initialize: (options) ->

      _.defaults options,
        forceRefresh: false
        surveyId: false

      permissions = App.request 'permissions:current'

      reminders = App.request 'reminders:current'
      surveys = App.request 'surveys:saved'

      @layout = @getLayoutView permissions

      @listenTo permissions, "localnotification:checked", =>
        App.execute "reminders:force:refresh"

      if !options.forceRefresh
        @listenTo permissions, "localnotification:registered", =>
          App.execute "reminders:force:refresh"

      # @surveyId is used to populate the reminders list with a new reminder,
      # with a specific survey selected. Currently used from the survey
      # completion page to encourage users to create a new reminder.
      @surveyId = options.surveyId

      @listenTo @layout, "show", =>
        console.log "showing layout"
        if permissions.get('localNotification') is true

          if surveys.length is 0
            @noticeRegion "No saved #{App.dictionary('pages','survey')}! Download #{App.dictionary('pages','campaign')} from the #{App.dictionary('pages','campaign').capitalizeFirstLetter()} Menu section to create new #{App.dictionary('pages','reminder')}."
          else
            @initBlockerView()
            @listRegion reminders
            if @surveyId then App.execute("reminders:add:new")

        else
          # attempt to register permissions here if it's false.
          App.execute "permissions:register:localnotifications"

      @listenTo App.vent, "blocker:reminder:update:reset", =>
        # blocker view has been destroyed. You must
        # re-initialize a new blockerView to show it again.
        @initBlockerView()

      @show @layout

    noticeRegion: (message) ->
      notice = new Backbone.Model message: message
      noticeView = @getNoticeView notice

      @show noticeView, region: @layout.noticeRegion

    initBlockerView: ->
      @blockerView = @getBlockerView()

      @listenTo @blockerView, "render", (blockerView) =>
        console.log 'blockerView render'
        startingSurvey = if @surveyId then @surveyId else blockerView.model.get('surveyId')
        surveysView = @getReminderSurveysView App.request("reminders:surveys", startingSurvey)
        blockerView.surveysRegion.show surveysView

        @listenTo surveysView, "survey:selected", (model) ->
          console.log 'survey:selected model', model
          blockerView.model.trigger "survey:selected", model

      @listenTo @blockerView, "reminder:submit", (model, response) =>
        console.log 'reminder:submit model', model
        App.vent.trigger "reminders:reminder:submit", model, response

      @listenTo @blockerView, "new:revert", (model) =>
        # delete the model when the new item is reverted.
        App.vent.trigger "reminders:reminder:delete", model

      @listenTo @blockerView, "delete:reminder", (view) =>
        console.log 'reminder:delete view', view
        App.vent.trigger "reminders:reminder:delete", view.model

    listRegion: (reminders) ->
      listView = @getListView reminders

      @listenTo reminders, 'date:future:shift', =>
        @blockerView.trigger "show:future:date"

      @listenTo reminders, "add", (model) ->
        @activateBlocker model

      @listenTo App.vent, "blocker:reminder:update:cancel", =>
        @blockerView.trigger "revert:all", App.request("reminders:surveys")

      @listenTo listView, "childview:before:render", (childView) =>
        if childView.model.get('surveyId') is false
          # set the surveyId and surveyTitle if they're not set yet.
          # (they default to `false`)
          reminderSurveys = App.request("reminders:surveys")
          selectedSurvey = if @surveyId then reminderSurveys.findWhere(id: @surveyId) else reminderSurveys.at(0)
          childView.model.trigger "survey:selected", selectedSurvey

      @listenTo listView, "childview:active:complete", (options) ->
        console.log 'active:complete model' , options.model
        App.vent.trigger "reminder:toggle", options.model

      @listenTo listView, "childview:click:edit", (view) =>
        # update the blockerView's model to the selected reminders
        # list view Reminder model.
        @activateBlocker view.model

      @listenTo reminders, "invalid", (reminderModel) =>
        # reminder submit validation failed
        console.log "reminder invalid, errors are", reminderModel.validationError
        App.vent.trigger "reminder:validate:fail", reminderModel.validationError


      @listenTo reminders, "validated:success", (model) =>
        # reminder validation succeeded
        App.vent.trigger "reminder:set:success", model


      @show listView, region: @layout.listRegion

    activateBlocker: (reminder) ->
      @blockerView.model = reminder
      App.vent.trigger "blocker:reminder:update", reminderView: @blockerView

    getReminderSurveysView: (surveys) ->
      new List.ReminderSurveys
        collection: surveys

    getNoticeView: (notice) ->
      new List.Notice
        model: notice

    getBlockerView: ->
      new List.UpdateBlocker

    getListView: (reminders) ->
      new List.Reminders
        collection: reminders

    getLayoutView: (permissions) ->
      console.log 'permissions', permissions
      new List.Layout
        model: permissions
