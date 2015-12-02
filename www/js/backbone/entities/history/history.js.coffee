@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The History Entity generates the user's saved response history.

  currentHistory = false

  # This private variable exists so "history:entries" can be requested in
  # multiple places on the same page without issue. If the history
  # is already fetching, it doesn't try to fetch again.
  currentlyFetching = false

  class Entities.UserHistoryEntry extends Entities.Model

  class Entities.UserHistoryEntriesByCampaign extends Entities.Collection
    model: Entities.UserHistoryEntry
    url: ->
      "#{App.request("serverpath:current")}/app/survey_response/read"

    getResponseFromObj: (response) ->
      switch response.prompt_type
        when 'single_choice'
          selectionIndex = response.prompt_response
          response.prompt_choice_glossary[selectionIndex].label
        when 'multi_choice'
          # returns a JSON string of all of the responses
          result = _.map response.prompt_response, (selectionIndex) ->
            response.prompt_choice_glossary[selectionIndex].label
          JSON.stringify result
        when 'multi_choice_custom'
          # returns a JSON string of all of the responses
          JSON.stringify response.prompt_response
        else
          response.prompt_response

    addSorting: (results) ->
      sortParams = {}
      if App.custom.functionality.history_eqis_bucketing isnt false
        if results.survey_id in App.custom.functionality.history_eqis_bucketing.firstresponse_surveyids
          # if it's a matching survey ID in the first response
          # survey IDs config array, use the first prompt
          # response as the bucket.
          firstKey = false
          _.find results.responses, (response, key) ->
            if response.prompt_index is 0
              firstKey = key
              return true
            else
              return false
          firstResponse = results.responses[firstKey]
          paddedResponse = "0#{@getResponseFromObj(firstResponse)}".slice('-2')
          sortParams.bucket = "Day #{paddedResponse}"
        else
          # all other surveys just use the survey title as the bucket.
          sortParams.bucket = results.survey_title
      else
        sortParams.bucket = results.date

      sortParams.sortIndex = "#{sortParams.bucket}:#{results.utc_timestamp}"

      _.extend(results, sortParams)

    addEntryListMetaProperties: (results) ->
      # adds list meta properties to an entry:
      # list_second_label - additional label in the history list
      # list_icon_type - bases the icon on the contents of the history item
      metaProperties = {}

      if App.custom.functionality.history_eqis_bucketing isnt false and 
          results.survey_id in App.custom.functionality.history_eqis_bucketing.firstresponse_surveyids

        # set the meta property for second list label
        # only for bucketed survey IDs
        # eQIS uses the second prompt value, not the first
        secondKey = false
        _.find results.responses, (response, key) ->
          if response.prompt_index is 1
            secondKey = key
            return true
          else
            return false
        secondResponse = results.responses[secondKey]
        # make sure not displayed or skipped responses are not shown
        if secondResponse.prompt_response in ["NOT_DISPLAYED","SKIPPED"] then secondResponse = false
        metaProperties.list_second_label = @getResponseFromObj(secondResponse)
      else
        # second list label is blank otherwise, set to false
        metaProperties.list_second_label = false

      # set the list icon type, default is text
      metaProperties.list_icon_type = 'text'

      # loops through all responses.
      # finds the first matching response of photo, doc or video,
      # sets the list icon type to this first matching item,
      # then exits
      _.find results.responses, (response) ->
        if response.prompt_type in ['photo','document','video'] and response.prompt_response not in ["NOT_DISPLAYED", "SKIPPED"]
          metaProperties.list_icon_type = response.prompt_type
          return true
        else
          return false
      _.extend(results, metaProperties)

    makeHistoryMediaIndex: (results) ->
      mediaIndex = []
      _.each results.responses, (response) ->
        if response.prompt_type in ['photo','document'] and response.prompt_response not in ["NOT_DISPLAYED", "SKIPPED"]
          mediaIndex.push
            context: if response.prompt_type is 'photo' then 'image' else 'media'
            id: response.prompt_response
      App.execute "history:media:queue:add", mediaIndex

    parse: (response, options) ->
      # parse JSON into individual responses with campaign metadata


      # there are no responses for the campaign at all.
      if response.data.length is 0 then return []


      # Only want to create a new Entry for a valid entry.
      # The .map() creates a new array, each key is object or false.
      # The .filter() removes the false keys.

      campaignEntries = _.chain(response.data).map((value, key) =>
        # possible TODO: add return false the entry is somehow invalid.
        results = {
          id: value.survey_key
          date: value.date
          timestamp: value.timestamp
          timezone: value.timezone
          utc_timestamp: value.utc_timestamp
          campaign_urn: options.campaign.id
          survey_id: value.survey_id
          survey_title: value.survey_title
          location:
            location_status: value.location_status
            location_timestamp: value.location_timestamp
            location_timezone: value.location_timezone
            latitude: value.latitude
            longitude: value.longitude
            provider: value.provider
            accuracy: value.accuracy
          campaign: options.campaign.toJSON()
          survey:
            description: value.survey_description
          responses: value.responses
        }
        results = @addSorting(results)
        @makeHistoryMediaIndex(results)
        return @addEntryListMetaProperties(results)
      ).filter((result) -> !!result).value()
      campaignEntries

  class Entities.UserHistoryEntries extends Entities.Collection
    model: Entities.UserHistoryEntry
    comparator: "sortIndex"

  API =
    init: ->
      App.request "storage:get", 'history_responses', ((result) =>
        # saved history retrieved from raw JSON.
        console.log 'saved history responses retrieved from storage'
        currentHistory = new Entities.UserHistoryEntries result
        App.vent.trigger "history:saved:init:success"
      ), =>
        console.log 'saved history responses not retrieved from storage'
        currentHistory = new Entities.UserHistoryEntries
        App.vent.trigger "history:saved:init:failure"

    updateLocal: (callback) ->
      # update localStorage with the current history
      App.execute "storage:save", 'history_responses', currentHistory.toJSON(), callback

    fetchHistory: (campaign_urns) ->
      App.vent.trigger "history:fetch:start"
      App.vent.trigger 'loading:show', "Fetching History..."
      campaignCollections = []
      responseFetchSuccess = []

      myData =
        # add start date - 3 months ago
        # if start date, end date is also required
        client: App.client_string
        column_list: "urn:ohmage:special:all"
        prompt_id_list: "urn:ohmage:special:all"
        output_format: "json-rows"
        user_list: App.request "credentials:username"
      myData = _.extend(myData, App.request("credentials:upload:params"))

      _.each campaign_urns, (campaign_urn) ->
        myData.campaign_urn = campaign_urn
        myCampaign = new Entities.UserHistoryEntriesByCampaign
        campaignCollections.push myCampaign

        currentlyFetching = true
        myCampaign.fetch
          reset: true
          type: "POST"
          data: myData
          campaign: App.request "campaign:entity", campaign_urn
          success: (collection, response, options) =>
            if response.result isnt "failure"
              responseFetchSuccess.push true
            else
              responseFetchSuccess.push false

          error: (collection, response, options) =>
            responseFetchSuccess.push false

      currentHistory._fetch = new $.Deferred()

      App.execute "when:fetched:always", campaignCollections, =>
        if _.contains(responseFetchSuccess, false)
          # there was an error while fetching one of the campaign's history entries
          App.execute "dialog:alert", "Unable to update history, history can be updated when the connection error resolves."
          App.vent.trigger "history:entries:fetch:error"
        else
          # no errors, merge all of the fetched collections into the main history collection.

          currentHistory.reset _.chain(campaignCollections).map((collection) -> collection.toJSON()).flatten().value()

          App.vent.trigger "history:entries:fetch:success", currentHistory

          @updateLocal( =>
            App.vent.trigger "history:entries:fetch:storage:success", currentHistory
          )

        # resolve the fetch handler.
        currentlyFetching = false
        currentHistory._fetch.resolve()
        currentHistory.trigger "sync:stop", currentHistory

      currentHistory

    getHistory: ->
      if currentHistory.length < 1 and currentlyFetching is false
        # fetch all history from the server,
        # because our current version is empty
        campaign_urns = App.request 'campaigns:saved:urns'
        if campaign_urns.length is 0 then return false

        @fetchHistory campaign_urns
      else
        # just return the collection
        currentHistory
    getEntryResponses: (rawResponsesObj) ->
      result = _.map rawResponsesObj, (response, key) ->
        # flatten the raw object representation
        # to a flattened array of objects.
        _.extend(response, id: key)
      result
    removeServerEntry: (entry) ->

      myData =
        client: App.client_string
        campaign_urn: entry.get 'campaign_urn'
        survey_key: entry.get 'id'

      $.ajax
        type: 'POST' # not RESTful but the Ohmage 2.0 API requires it
        data: _.extend(myData, App.request("credentials:upload:params"))
        url: "#{App.request("serverpath:current")}/app/survey_response/delete"
        dataType: 'json'
        success: (response) =>
          if response.result is "success"
            @removeLocalEntry entry
          else
            App.vent.trigger "history:entry:remove:error", entry, "Error: #{response.errors[0].text}"
        error: (xhr, ajaxOptions, thrownError) =>
          App.vent.trigger "history:entry:remove:error", entry, "Network Error, unable to delete responses."

    removeLocalEntry: (entry) ->
      currentHistory.remove entry

      @updateLocal( =>
        App.vent.trigger 'history:entry:remove:success', entry
      )

    removeByCampaign: (campaign_urn) ->
      removed = currentHistory.where(campaign_urn: campaign_urn)
      currentHistory.remove removed

      @updateLocal( =>
        App.vent.trigger "history:entries:removed:success", removed
      )

    clear: ->
      currentHistory = new Entities.UserHistoryEntries

      App.execute "storage:clear", 'history_responses', ->
        console.log 'history responses erased'
        App.vent.trigger "history:saved:cleared"


  App.reqres.setHandler "history:entry", (id) ->
    currentHistory.get id

  App.reqres.setHandler "history:entry:responses:raw", (id) ->
    API.getEntryResponses currentHistory.get(id).get('responses')

  App.reqres.setHandler "history:entries", ->
    API.getHistory()

  App.on "before:start", ->
    API.init()

  App.commands.setHandler "history:sync", ->
    campaign_urns = App.request 'campaigns:saved:urns'
    if campaign_urns.length is 0 then return false

    API.fetchHistory campaign_urns

  App.commands.setHandler "history:entry:remove", (entry) ->
    API.removeServerEntry entry

  App.vent.on "campaign:saved:remove", (campaign_urn) ->
    API.removeByCampaign campaign_urn

  App.vent.on "credentials:cleared", ->
    API.clear()

  App.vent.on "uploadqueue:remove:success survey:exit survey:reset", ->
    if App.custom.functionality.history_auto_refresh
      campaign_urns = App.request 'campaigns:saved:urns'

      API.fetchHistory campaign_urns
