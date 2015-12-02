@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The survey Entity deals with data relating to a single survey.
  # This module handles the upload process.

  API =
    prepResponseUpload: (currentResponses, currentFlow) ->
      currentResponses.map( (response) =>
        myId = response.get 'id'
        myResponse = App.request "response:value:parsed", { stepId: myId, addUploadUUIDs: true }
        {
          prompt_id: myId
          value: myResponse
        }
      )

    uploadSurvey: (options) ->
      { currentResponses, location, surveyId } = options

      submitResponses = @prepResponseUpload currentResponses

      currentTime = moment().valueOf()
      currentTZ = _.jstz()

      submitSurveys = 
        survey_key: _.guid()
        time: currentTime
        timezone: currentTZ
        location_status: if location then "valid" else "unavailable"
        survey_id: App.request "survey:saved:server_id", surveyId
        survey_launch_context: App.request "survey:launchcontext"
        responses: submitResponses

      if location
        # if the location status is unavailable,
        # it is an error to send a location object.
        submitSurveys.location = location

      # campaign_urn serves as the "foreign key" between
      # surveysSaved and CampaignsUser
      campaign_urn = App.request "survey:saved:urn", surveyId
      myCampaign = App.request "campaign:entity", campaign_urn

      completeSubmit =
        client: App.client_string
        images: App.request "survey:images:string"
        surveys: JSON.stringify([submitSurveys])
        campaign_creation_timestamp: myCampaign.get('creation_timestamp')
        campaign_urn: campaign_urn

      App.execute "filemeta:move:native", =>
        App.execute "uploader:new", 'survey', completeSubmit, surveyId

    getLocation: (responses, surveyId) ->
      # get geolocation
      location = App.request "geolocation:get"
      console.log 'getLocation location', location
      if location isnt false
        @uploadSurvey
          currentResponses: responses
          location: location
          surveyId: surveyId
      else
        App.execute("survey:geolocation:fetch", surveyId)

  App.commands.setHandler "survey:upload", (surveyId) ->
    # Other requests happen before the survey upload
    # request, but they are all part of the upload process.
    App.vent.trigger "uploadtracker:active"
    responses = App.request "responses:current"

    App.execute 'credentials:preflight:check', =>
      App.vent.trigger "loading:show", "Getting Location..."
      API.getLocation responses, surveyId

  App.vent.on "survey:geolocation:fetch:failure", (surveyId) ->
    console.log 'geolocation fetch failure', surveyId
    responses = App.request "responses:current"
    API.uploadSurvey
      currentResponses: responses
      location: false
      surveyId: surveyId

  App.vent.on "survey:geolocation:fetch:success", (surveyId) ->
    console.log 'geolocation fetch success', App.request "geolocation:get"
    responses = App.request "responses:current"
    API.uploadSurvey
      currentResponses: responses
      location: App.request "geolocation:get"
      surveyId: surveyId
