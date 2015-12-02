@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The Surveys Entity deals with data relating to all saved
  # surveys.

  currentSurveysSaved = false

  class Entities.SurveySaved extends Entities.Model
    defaults:
      status: 'running' # All surveys are running when first created

  class Entities.SurveysSaved extends Entities.Collection
    model: Entities.SurveySaved
    url: ->
      "#{App.request("serverpath:current")}/app/campaign/read"
    parse: (response, options) ->
      if response.result isnt "failure"
        console.log 'options in parse', options
        urn = options.data.campaign_urn_list
        campaignXML = response.data[urn].xml
        $XML = $( $.parseXML(campaignXML) )

        # we have to execute a command here,
        # since campaigns are a separate entity and
        # this is the central place where campaign/survey
        # XML is extracted.
        App.execute "campaigns:meta:set", urn, $XML.tagHTML("campaign > #{App.xmlMeta.rootLabel}")

        $surveys = $XML.find 'survey'
        @parseSurveysXML $surveys, urn, campaignXML
    comparator: (item) ->
      item.get('title').capitalizeFirstLetter()
    parseSurveysXML: ($surveysXML, urn, campaignXML) ->
      _.map($surveysXML, (survey) ->
        $survey = $(survey)
        myId = $survey.tagText('> id')
        {
          id: "#{urn}:#{myId}"
          server_id: myId
          title: $survey.tagText('title')
          description: $survey.tagText('description')
          xmlStr: my$XmlToString($survey).trim()
          campaign_urn: urn
          meta: App.request('xmlmeta:xml:to:json', $survey.tagHTML("> #{App.xmlMeta.rootLabel}"))
          parent_meta: App.request('campaigns:meta:get', urn)
        }
      )

  API =
    init: ->
      App.request "storage:get", 'saved_surveys', ((result) =>
        # user saved surveys retrieved from raw JSON.
        console.log 'user saved surveys retrieved from storage'
        currentSurveysSaved = new Entities.SurveysSaved result
        App.vent.trigger('surveys:saved:load:complete')
      ), =>
        console.log 'user saved surveys not retrieved from storage'
        currentSurveysSaved = new Entities.SurveysSaved
        App.vent.trigger('surveys:saved:load:complete')

    getSurveys: (campaign_urn) ->
      console.log campaign_urn
      myData =
        client: App.client_string
        output_format: 'long'
        campaign_urn_list: campaign_urn
        user_role: "participant"
      currentSurveysSaved.fetch
        reset: false
        remove: false # merge any newly fetched surveys with existing ones based on ID
        type: 'POST' # not RESTful but the 2.0 API requires it
        data: _.extend(myData, App.request("credentials:upload:params"))
        success: (collection, response, options) =>
          console.log 'surveys fetch attempt complete', response, collection, options

          if response.result isnt "failure"
            @updateLocal( =>
              App.vent.trigger 'surveys:saved:campaign:fetch:success', options.data.campaign_urn_list
            )
          else
            message = "The following errors prevented the #{App.dictionary('page','campaign')} from downloading: "
            _.every response.errors, (error) =>
              message += error.text
              if error.code in ["0200","0201","0202"]
                App.vent.trigger "surveys:saved:campaign:fetch:failure:auth", error.text
                return false
            App.vent.trigger 'surveys:saved:campaign:fetch:error', options.data.campaign_urn_list, message
        error: (collection, response, options) =>
          console.log 'surveys fetch error'
          App.vent.trigger 'surveys:saved:campaign:fetch:error', options.data.campaign_urn_list, "Network error fetching #{App.dictionary('page','campaign')}."
    getCampaignSurveys: (urn) ->
      surveys = currentSurveysSaved.where
        campaign_urn: urn
      new Entities.SurveysSaved surveys
    removeSurveys: (urn) ->
      currentSurveysSaved.remove currentSurveysSaved.where(campaign_urn: urn)
      @updateLocal( =>
        App.vent.trigger 'surveys:saved:campaign:remove:success', urn
      )
    updateLocal: (callback) ->
      # update localStorage index saved_surveys with the current version of campaignsSaved entity
      App.execute "storage:save", 'saved_surveys', currentSurveysSaved.toJSON(), callback
    clear: ->
      currentSurveysSaved = new Entities.SurveysSaved

      App.execute "storage:clear", 'saved_surveys', ->
        console.log 'user saved surveys erased'
        App.vent.trigger "surveys:saved:cleared"
    getSurveyAttr: (id, key) ->
      mySurvey = currentSurveysSaved.get id
      mySurvey.get key
    getSurveyXML: (id) ->
      # this fetches a single survey's xml by it's ID.
      xmlStr = @getSurveyAttr id, 'xmlStr'
      $( $.parseXML(xmlStr) )

  App.reqres.setHandler "survey:saved:xml", (id) ->
    # note the survey's id is formatted `campaign_urn:server_id`
    API.getSurveyXML id

  App.reqres.setHandler "survey:saved:urn", (id) ->
    # note the survey's id is formatted `campaign_urn:server_id`
    API.getSurveyAttr id, 'campaign_urn'

  App.reqres.setHandler "survey:saved:server_id", (id) ->
    # note the survey's id is formatted `campaign_urn:server_id`
    API.getSurveyAttr id, 'server_id'

  App.reqres.setHandler "survey:saved:title", (id) ->
    # note the survey's id is formatted `campaign_urn:server_id`
    API.getSurveyAttr id, 'title'

  App.reqres.setHandler "survey:saved:description", (id) ->
    # note the survey's id is formatted `campaign_urn:server_id`
    API.getSurveyAttr id, 'description'

  App.on "before:start", ->
    API.init()

  App.vent.on "campaign:saved:add", (campaign_urn) ->
    API.getSurveys campaign_urn

  App.vent.on "campaign:saved:remove", (campaign_urn) ->
    API.removeSurveys campaign_urn

  App.commands.setHandler "debug:surveys:saved:campaign:fetch", (campaign_urn) ->
    API.getSurveys campaign_urn

  App.commands.setHandler "debug:surveys:saved:campaign:remove", (campaign_urn) ->
    API.removeSurveys campaign_urn

  App.commands.setHandler "debug:surveys:modify", (id, JSON) ->
    mySurveys = currentSurveysSaved.get id
    mySurveys.set JSON
    console.log 'modified surveys', mySurveys.toJSON()

  App.reqres.setHandler "surveys:saved", ->
    currentSurveysSaved

  App.reqres.setHandler "surveys:saved:campaign", (campaign_urn) ->
    API.getCampaignSurveys campaign_urn

  App.vent.on "credentials:cleared", ->
    API.clear()
