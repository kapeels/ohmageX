@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The History Entity generates the user's saved response history.

  class Entities.eQISArtifact extends Entities.Model

  class Entities.eQISArtifacts extends Entities.Collection
    model: Entities.eQISArtifact
    initialize: (models, options) ->
      @entries = models
      @campaign_urn = options.campaign_urn

      # only create this listener if entries is an actual Collection.
      if @entries instanceof Entities.UserHistoryEntries
        @listenTo @entries, "sync:stop reset", =>
          @reset @entries, parse: true

    numDays: 10 # number of days that the survey lasts.

    parse: (entries) ->

      # TODO: Decide where to put all of these survey and step IDs.
      # Should they be moved to the config?

      # establish scaffolding for all entries.
      if @entries? and @entries.length > 0 and @entries instanceof Entities.UserHistoryEntries
        # limit entries to matching passed-in campaign URN
        @entries_campaign = @entries.where(campaign_urn: @campaign_urn)
        # update all of the response counts
        responseCounts = @getResponseCounts @entries_campaign

      else
        # just prepoulate it with an array of @numDays+2 items all containing zero.
        # we use @numDays+2 because there are two additional surveys.

        # Note: Setting step in _.range() to zero does NOT make an array
        # of identical zeros - the step value is ignored.
        responseCounts = _.range(0,@numDays+2,0).map(_.constant(0))

      results = [
          rowLabel: "Initial"
          bucket: "A Initial Reflection"
          navbucket: "A. Initial Reflection"
          surveyId: '1InitialReflection'
          secondSurveyId: false
          newPrepopIndex: false
          newPrepopfirstSurveyStep: false
          newPrepopSecondSurveyStep: false
          responseCount: responseCounts[0]
      ]

      days = []
      _.each responseCounts, (count, index) =>
        if index > 0 and index < @numDays+1

          paddedIndex = "0#{index}".slice('-2')

          days.push
            rowLabel: "Day #{paddedIndex}"
            bucket: "Day #{paddedIndex}"
            navbucket: "Day #{paddedIndex}"
            surveyId: '2AssessmentArtifacts'
            secondSurveyId: '3InstructionArtifacts'
            newPrepopIndex: index
            newPrepopfirstSurveyStep: "AssessmentArtifactDayFolder"
            newPrepopSecondSurveyStep: "InstructionalArtifactDayFolder"
            responseCount: count

      results = results.concat days

      # add suffix results
      results = results.concat [
        rowLabel: "Concluding"
        bucket: "Z Concluding Reflection"
        navbucket: "Z. Concluding Reflection"
        surveyId: '4ConcludingReflection'
        secondSurveyId: false
        newPrepopIndex: false
        newPrepopfirstSurveyStep: false
        newPrepopSecondSurveyStep: false
        responseCount: responseCounts[@numDays+1]
      ]
      console.log 'results', results
      results

    getResponseCounts: (entries) ->
      # get a pre-populated array of numbers from 1 - numDays
      dayNumbers = _.range(1,@numDays+1,1)
      # get buckets, converting spaces into underscores
      # so they can be mapped to object properties
      bucketCountsObj = _.countBy entries, (entry) -> "#{entry.get('bucket')}".replace(/\s/g, "_").replace(/\./g, "")
      # returns an object like:
      # {bucket_1: 3, bucket_3: 4, ... }
      results = []
      results[0] = if "A_Initial_Reflection" of bucketCountsObj then bucketCountsObj.A_Initial_Reflection else 0
      # returns an array of 10 items, with bucket count in sequence.
      results = results.concat( _.map dayNumbers, (dayNumber) ->
        # we mapped the spaces to underscores, include an underscore here!

        paddedDayNumber = "0#{dayNumber}".slice('-2')

        targetBucket = "Day_#{paddedDayNumber}"
        if targetBucket of bucketCountsObj
          # The key exists.
          # return the value of this bucket's count.
          return bucketCountsObj[targetBucket]
        else
          # key does not exist, its count is zero.
          return 0
      )
      results[@numDays+1] = if "Z_Concluding_Reflection" of bucketCountsObj then bucketCountsObj.Z_Concluding_Reflection else 0
      results

  API =
    getArtifacts: (entries, campaign_urn) ->
      new Entities.eQISArtifacts entries,
        parse: true
        campaign_urn: campaign_urn

  App.reqres.setHandler "dashboardeqis:artifacts", (campaign) ->
    entries = App.request "history:entries"
    API.getArtifacts entries, campaign.get("id")
