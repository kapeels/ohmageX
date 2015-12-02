@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # Reminders entity.
  # Note: Local notification permissions are a concern for iOS 8+ and Android (if disabled)
  # this requires interaction with the Permissions entity.
  # This interacts with the system notifications entity.

  # id - String - Unique ID for the reminder. Generated per reminder.
  # activationDate - Moment() object - When the reminder is activated.
  # active - Boolean - If the reminder is actually activated or just stored.
  # notificationIds - Array (Strings) - System notification IDs assigned to this reminder.
  # repeat - Boolean - If true then this reminder repeats
  # repeatDays - Array (Integers) - List of repeating days 0 thru 6. 0 is Sunday.
  # surveyId - String - ID of the survey to use.
  # surveyTitle - String - Title of the survey. Used in views


  class Entities.Reminder extends Entities.ValidatedModel
    initialize: (options) ->
      @listenTo @, 'survey:selected', @selectSurvey
      @listenTo @, 'internal:success', @propagateResponses
      @listenTo @, 'change:activationDate change:active', @adjustFutureDate
      # Be sure to initialize activationDate as a moment if it's provided on init.
      # If retrieving from localStorage, the activationDate is stored as a string.
      if options.activationDate? then @set('activationDate', moment(options.activationDate))
    propagateResponses: (attrs) ->
      # delete the 'response' and 'properties' properties
      # because they're validation placeholders.
      delete attrs.properties
      delete attrs.response
      result = new Entities.Reminder attrs
      @trigger 'validated:success', result
    selectSurvey: (surveyModel) ->
      @set('surveyTitle', surveyModel.get('title'))
      @set('surveyId', surveyModel.get('id'))
      @set('campaign', surveyModel.get('campaign_urn'))
    adjustFutureDate: ->
      currentDate = @get 'activationDate'
      if moment().diff(currentDate) > 0
        # the current date and time is in the past.
        # get the next daily occurrence of this hour minute and second.
        @set {activationDate: @nextHourMinuteSecond(currentDate, 'days')}, {silent: true}
        @trigger "date:future:shift"
    nextHourMinuteSecond: (myMoment, interval) ->
      # gets the next occurrence of a moment's hours, minutes, and seconds.
      # Ignores the month, day and year.
      # it jumps ahead by the given 'interval' for the next occurrence.
      # expected - Moment.js intervals like 'days' or 'weeks'

      input = moment(myMoment)

      hour = input.hour()
      minute = input.minute()
      output = moment().startOf('day').hour(hour).minute(minute).second(0)

      if output > moment() then output else output.add(1, interval)
    validate: (attrs, options) ->
      # defining a placeholder value here,
      # so a property can be passed into the rulesMap.
      attrs.properties =
        activationDate: true
      attrs.response = attrs.activationDate
      myRulesMap =
        futureTimestamp: 'activationDate'
      super attrs, options, myRulesMap
    newBumpedWeekdayHourMinuteDate: (options) ->
      # retuns a new date base on the provided weekday, hour and minute,
      # with any past dates bumped to the future by the provided pastBumpInterval.

      _.defaults options,
        # default to bumping everything 2 minutes from now.
        bumpAfter: moment().add(2, 'minutes')

      { weekday, hour, minute, pastBumpInterval, bumpAfter } = options

      newDate = moment().startOf('week').day(weekday).hour(hour).minute(minute)

      if weekday < bumpAfter.day()
        # in this week, the provided day comes before today's
        # day of the week. Bump it
        # (watch for type conversion here)
        newDate.add(1, pastBumpInterval)

      else if weekday is bumpAfter.day()
        # the provided weekday matches today's day of the week

        console.log "newDate", newDate.format("MM/DD/YYYY, h:mma")
        console.log "bumpAfter", bumpAfter.format("MM/DD/YYYY, h:mma")

        if newDate.diff(bumpAfter) < 0
          console.log "DATE IS IN THE PAST"
          # the new date is in the past, bump it
          newDate.add(1, pastBumpInterval)

      console.log "reminder NEW BUMPED SCHEDULE TIME", newDate.format("MM/DD/YYYY, h:mma")

      newDate

    defaults: ->

      return {
        id: _.guid()
        activationDate: moment( moment() + 60 * 1000)
        active: false
        notificationIds: []
        repeat: false
        repeatDays: []
        renderVisible: false
        surveyId: false
        surveyTitle: false
        campaign: false
      }

  class Entities.Reminders extends Entities.Collection
    model: Entities.Reminder
    initialize: ->
      @listenTo @, "survey:selected date:future:shift", =>
        App.execute "storage:save", 'reminders', @toJSON(), =>
          console.log "reminders entity Reminders Collection survey:selected storage success"
      @listenTo @, "change:activationDate", =>
        @sort()

    comparator: (model) ->
      # sort by the hour, minute and second.
      input = moment(model.get('activationDate'))
      hour = input.hour()
      minute = input.minute()

      moment().startOf('day').hour(hour).minute(minute).second(0).unix()

  currentReminders = false

  API =
    init: ->
      App.request "storage:get", 'reminders', ((result) =>
        # saved reminders retrieved from raw JSON.
        console.log 'saved reminders retrieved from storage'
        currentReminders = new Entities.Reminders result
        App.vent.trigger "reminders:saved:init:success"
      ), =>
        console.log 'saved reminders not retrieved from storage'
        currentReminders = new Entities.Reminders
        App.vent.trigger "reminders:saved:init:failure"


    addNewReminder: ->
      console.log 'addReminder'
      currentReminders.add({}, { validate: false })

    toggleSystemNotifications: (reminder) ->
      if reminder.get('active') is true
        App.execute "system:notifications:turn:on", reminder
      else
        # This reminder has been disabled. Be sure to deactivate its notifications.
        console.log 'toggleSystemNotifications disabled notification ids', reminder.get('notificationIds')
        App.execute "system:notifications:turn:off", reminder

    purgeExpired: ->
      expired = currentReminders.filter (reminder) =>
        if reminder.get('active') and !reminder.get('repeat')
          # active, non-repeating reminder. Is it a date in the past?
          return moment().diff(moment(reminder.get('activationDate'))) > 0
        false
      console.log 'expired reminders', expired

      if expired.length > 0
        currentReminders.remove expired
        @updateLocal( =>
          console.log "reminders entity API.purgeExpired storage success"
        )

    getReminders: ->
      @purgeExpired()
      currentReminders

    validateReminder: (model, response) ->
      console.log 'validateReminder'
      if response.repeat and response.repeatDays.length is 0
        App.vent.trigger "reminder:validate:fail", 'Please select days to repeat this reminder.'
        return false
      console.log 'validateReminder model', model
      console.log 'response', response
      reminder = currentReminders.get(model)
      validateIt = response.active and !response.repeat

      reminder.set response, { validate: validateIt }

      if !validateIt then reminder.trigger("validated:success", reminder)

      @updateLocal( =>
        console.log "reminders entity API.validateReminder storage success"
      )

    deleteReminder: (reminderId) ->

      myReminder = currentReminders.get reminderId
      currentReminders.remove myReminder


      @updateLocal( =>
        console.log "reminders entity API.deleteReminder storage success"
        App.vent.trigger "reminder:delete:success", myReminder
      )

    removeCampaignReminders: (campaign_urn) ->
      console.log 'removedCampaignReminders urn', campaign_urn

      console.log 'currentReminders', currentReminders.toJSON()

      removed = currentReminders.where
        campaign: campaign_urn

      _.each removed, (reminder) =>
        console.log 'reminder ID', reminder.get 'id'
        App.execute "system:notifications:turn:off", reminder

      currentReminders.remove removed

      @updateLocal( =>
        console.log "campaign reminders removed from localStorage"
        App.vent.trigger "reminders:campaign:remove:success", campaign_urn
      )

    setAttribute: (reminderId, attribute, value) ->
      reminder = currentReminders.get reminderId
      reminder.set attribute, value

      @updateLocal( =>
        console.log "reminder notification #{attribute} set", value
      )

    bumpRepeatingDate: (reminderId, bumpAfter) ->
      reminder = currentReminders.get reminderId
      throw new Error "can only bump repeating reminders, #{reminderId} is non-repeating" if reminder.get('repeat') is false
      # bump a repeating reminder's activationDate.
      targetHour = reminder.get('activationDate').hour()
      targetMinute = reminder.get('activationDate').minute()

      if reminder.get('repeatDays').length is 7
        # if it's daily, it bumps it to tomorrow's next hour:minute
        newDate = reminder.newBumpedWeekdayHourMinuteDate
            weekday: moment().day()
            hour: targetHour
            minute: targetMinute
            pastBumpInterval: 'days'
            bumpAfter: bumpAfter

      else
        # if it's non-consecutive repeating, it bumps it to the next occurrence
        # after the end of the day.
        nextOccurrence = false
        occurrenceFutureInterval = false

        _.each reminder.get('repeatDays'), (repeatDay) =>

          repeatDate = reminder.newBumpedWeekdayHourMinuteDate
            weekday: parseInt(repeatDay) # type conversion required for day comparison
            hour: targetHour
            minute: targetMinute
            pastBumpInterval: 'weeks'
            bumpAfter: bumpAfter

          if occurrenceFutureInterval is false or repeatDate.diff(moment()) < occurrenceFutureInterval
            # get the date with the smallest interval after the present.
            nextOccurrence = repeatDate
            occurrenceFutureInterval = repeatDate.diff(moment())

        newDate = nextOccurrence

      reminder.set 'activationDate', newDate

    updateLocal: (callback) ->
      # update localStorage index reminders with the current version of campaignsSaved entity
      App.execute "storage:save", 'reminders', currentReminders.toJSON(), callback

    clear: (options = {}) ->
      currentReminders = new Entities.Reminders

      App.execute "storage:clear", 'reminders', ->
        console.log 'saved reminders erased'
        App.vent.trigger "reminders:all:clear:complete", options

  App.vent.on "surveys:saved:load:complete", ->
    API.init()

  App.commands.setHandler "reminders:all:clear", (options) ->
    API.clear options

  App.vent.on "credentials:cleared", ->
    API.clear()

  App.reqres.setHandler "reminders:current", ->
    API.getReminders()

  App.commands.setHandler "reminders:add:new", ->
    if App.request('surveys:saved').length > 0
      API.addNewReminder()

  App.commands.setHandler "reminder:delete", (model) ->
    App.execute "system:notifications:turn:off", model
    API.deleteReminder model.get 'id'

  App.commands.setHandler "reminder:delete:byid", (id) ->
    API.deleteReminder id

  App.commands.setHandler "reminder:validate", (model, response) ->
    API.validateReminder model, response

  App.commands.setHandler "reminder:notifications:set", (reminder, ids) ->
    # ids - array of IDs to set for the notification
    console.log "reminder:notifications:set ids", ids
    API.setAttribute reminder.get('id'), 'notificationIds', ids

  App.commands.setHandler "reminder:date:set", (reminder, date) ->
    API.setAttribute reminder.get('id'), 'activationDate', date

  App.commands.setHandler "reminder:repeating:date:bump:dayend:byid", (id) ->
    # bump this to after 11:59:59 of the current day.
    endOfDay = moment().startOf('day').hour(23).minute(59).second(59)
    API.bumpRepeatingDate id, endOfDay

  App.vent.on "campaign:saved:remove", (campaign_urn) ->
    if currentReminders.length > 0 then API.removeCampaignReminders(campaign_urn)

  App.vent.on "reminder:set:success", (reminderModel) ->
    API.toggleSystemNotifications reminderModel

  App.vent.on "reminder:toggle", (model) ->
    API.updateLocal ->
      console.log 'reminder toggle save complete'
    API.toggleSystemNotifications model
