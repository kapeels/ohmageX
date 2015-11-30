@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The CampaignsUser entity provides an interface for user Campaigns.
  # Campaigns can be retrieved by URN.
  # Campaign Status Codes:
  # available - campaign NOT saved, is available to the user to download
  # saved     - campaign saved locally, and surveys can be taken
  # ghost_stopped     - campaign saved locally, remote campaign stopped
  # ghost_outdated    - campaign saved locally, remote campaign wrong timestamp
  # ghost_nonexistent - campaign saved locally, remote campaign doesn't exist

  currentCampaignsUser = false

  class Entities.CampaignUser extends Entities.Model

  class Entities.CampaignsUser extends Entities.Collection
    model: Entities.CampaignUser
    url: ->
      "#{App.request("serverpath:current")}/app/campaign/read"
    comparator: (itemA, itemB) ->
      statusA = itemA.get('status')
      statusB = itemB.get('status')
      nameA = itemA.get('name')
      nameB = itemB.get('name')
      if statusA is 'saved' and statusB is 'saved'
        if nameA.capitalizeFirstLetter() > nameB.capitalizeFirstLetter() then return 1
        if nameA.capitalizeFirstLetter() < nameB.capitalizeFirstLetter() then return -1
        return 0
      else if statusA isnt 'saved' and statusB is 'saved' then return 1
      else if statusA is 'saved' and statusB isnt 'saved' then return -1
      else
        if nameA.capitalizeFirstLetter() > nameB.capitalizeFirstLetter() then return 1
        if nameA.capitalizeFirstLetter() < nameB.capitalizeFirstLetter() then return -1
        return 0

    parse: (response, options) ->
      # parse the response data into values ready to be added
      # to the Collection of User Campaigns.

      # Collect all savedIDs for later filtering.
      savedIDs = options.saved_campaigns.pluck 'id'
      console.log "savedIDs",savedIDs

      # Only want to create a Campaign entry for a campaign 
      # that is valid.
      # The .map() creates a new array, each key is object or false.
      # The .filter() removes the false keys.
      user = _.chain(response.data).map((value, key) =>
        matchingSaved = options.saved_campaigns.get(key)
        hasMatchingSaved = typeof matchingSaved isnt 'undefined'
        isRunningCampaign = value.running_state is "running"
        hasMatchingTimestamp = hasMatchingSaved and matchingSaved.get('creation_timestamp') is value.creation_timestamp

        if !hasMatchingSaved and !isRunningCampaign
          # filter invalid (non-running without matching saved
          # campaigns) campaigns from results completely.
          return false

        # before we go through the checks, we assume that a given
        # campaign is going to be "available"
        myStatus = 'available'

        if hasMatchingSaved
          # remove the matching campaign from our list of
          # saved IDs.
          savedIDs = _.without savedIDs, key

          if hasMatchingTimestamp
            if isRunningCampaign
              # timestamp matches, campaign is running
              myStatus = 'saved'
              App.vent.trigger "campaign:user:status:saved", key
            else
              # timestamp matches, campaign isn't running
              myStatus = 'ghost_stopped'
              App.vent.trigger "campaign:user:status:ghost", key, myStatus
          else
            # timestamp doesn't match
            myStatus = 'ghost_outdated'
            App.vent.trigger "campaign:user:status:ghost", key, myStatus

        return {
          id: key # campaign URN
          creation_timestamp: value.creation_timestamp
          name: value.name
          description: value.description
          status: myStatus
        }

      ).filter((result) -> !!result).value()
      user = @_appendNonexistent savedIDs, user, options.saved_campaigns
      user
    _appendNonexistent: (savedIDs, user, saved_campaigns) ->
      if savedIDs.length > 0
        # We have saved IDs that are not part of the existing user campaigns.
        # Create new ghost saved campaign entries for later merging into the final result.
        saved = _.map(savedIDs, (id) =>
          myCampaign = saved_campaigns.get id
          myStatus = 'ghost_nonexistent'
          App.vent.trigger "campaign:user:status:ghost", id, myStatus
          return {
            id: myCampaign.get 'id'
            creation_timestamp: myCampaign.get 'creation_timestamp'
            name: myCampaign.get 'name'
            description: myCampaign.get 'description'
            status: myStatus
          }
        )
        console.log "new saved", saved
        # merge ghosted campaigns into our final result.
        return _.uniq( _.union(user, saved), false, (item, key, id) -> item.id )
      else
        return user

  API =
    init: (saved_campaigns) ->

      App.request "storage:get", 'campaigns_user', ((result) =>
        # user campaigns retrieved from raw JSON.
        console.log 'user campaigns retrieved from storage'
        currentCampaignsUser = new Entities.CampaignsUser result
        @syncUserWithSaved(saved_campaigns)
      ), =>
        console.log 'user campaigns not retrieved from storage'
        currentCampaignsUser = new Entities.CampaignsUser

    syncUserWithSaved: (saved_campaigns) ->
      console.log 'syncUserWithSaved', saved_campaigns
      sync = currentCampaignsUser.chain().map((user_campaign) ->
        myStatus = user_campaign.get 'status'
        myId = user_campaign.get 'id'
        if saved_campaigns isnt false
          if myStatus is 'saved' or myStatus is 'available'
            matchingSaved = saved_campaigns.get myId
            hasMatchingSaved = typeof matchingSaved isnt 'undefined'
            if hasMatchingSaved
              user_campaign.set 'status', 'saved'
            else
              user_campaign.set 'status', 'available'
          return user_campaign
        else
          # saved_campaigns is empty
          if myStatus is 'saved' or myStatus is 'available'
            # set everything to available
            user_campaign.set 'status', 'available'
            return user_campaign
          else
            # eliminate all ghosted campaigns
            return false
      ).filter((result) -> !!result).value()
      currentCampaignsUser.reset sync
      @saveLocalCampaigns currentCampaignsUser
    syncCampaigns: ->
      App.vent.trigger 'loading:show', "Syncing #{App.dictionary('pages','campaign').capitalizeFirstLetter()}..."
      myData = 
        client: App.client_string
        output_format: 'short'
        user_role: "participant"
      currentCampaignsUser.fetch
        reset: true
        type: 'POST' # not RESTful but the 2.0 API requires it
        data: _.extend(myData, App.request("credentials:upload:params"))
        saved_campaigns: App.request 'campaigns:saved:current'
        success: (collection, response, options) =>
          console.log 'campaign fetch attempt complete', response, collection
          if response.result isnt "failure"
            @saveLocalCampaigns collection
          else
            message = "The following errors prevented the #{App.dictionary('pages','campaign')} from syncing: "
            showAlert = true
            _.every response.errors, (error) =>
              console.log 'error array item', error
              message += error.text
              if error.code in ["0200","0201","0202"]
                App.vent.trigger "campaigns:sync:failure:auth", error.text
                showAlert = false
                return false
            App.vent.trigger "campaigns:sync:failure"
            if showAlert then App.execute "dialog:alert", message
          App.vent.trigger "loading:hide"
        error: (collection, response, options) =>
          console.log 'campaign fetch error'
          App.execute "dialog:alert", "Network error syncing #{App.dictionary('pages','campaign')}."
          App.vent.trigger "campaigns:sync:failure"
          App.vent.trigger "loading:hide"
      currentCampaignsUser
    saveLocalCampaigns: (collection) ->
      # update localStorage index campaigns_user with the current version of campaignsUser entity
      App.execute "storage:save", 'campaigns_user', collection.toJSON(), =>
        console.log "campaignsUser entity saved in localStorage"
        App.vent.trigger "campaigns:sync:success", collection

    getCampaigns: ->
      if currentCampaignsUser.length < 1
        # fetch the campaign object from the server and sync,
        # because our current version is empty
        @syncCampaigns()
      else
        currentCampaignsUser
    getCampaign: (id) ->
      currentCampaignsUser.get id
    getCampaignName: (id) ->
      campaign = @getCampaign id
      campaign.get('name')
    setCampaignStatus: (id, status) ->
      console.log 'setCampaignStatus'
      currentCampaignsUser.get(id).set('status', status)
    removeCampaign: (id) ->
      console.log 'removeCampaign'
      myCampaign = currentCampaignsUser.get id
      switch myCampaign.get('status')
        when 'available'
          throw new Error "Invalid attempt to remove an available #{App.dictionary('page','campaign')}: #{id}"
        when 'saved'
          myCampaign.set('status', 'available')
        else
          currentCampaignsUser.remove myCampaign
          @saveLocalCampaigns currentCampaignsUser
    clear: ->
      currentCampaignsUser = new Entities.CampaignsUser

      App.execute "storage:clear", 'campaigns_user', ->
        console.log 'user campaigns erased'
        App.vent.trigger "campaigns:user:cleared"

  App.vent.on "campaigns:saved:init:success", ->
    console.log "campaigns:saved:init:success"
    API.init App.request("campaigns:saved:current")

  App.vent.on "campaigns:saved:init:failure", ->
    console.log "campaigns:saved:init:failure"
    API.init false

  App.vent.on "surveys:saved:campaign:fetch:success", (id) ->
    API.setCampaignStatus id, 'saved'

  App.vent.on "surveys:saved:campaign:remove:success", (id) ->
    API.removeCampaign id

  App.reqres.setHandler "campaign:entity", (id) ->
    API.getCampaign id

  App.reqres.setHandler "campaign:name", (id) ->
    API.getCampaignName id

  App.reqres.setHandler "campaigns:user", ->
    API.getCampaigns()

  App.commands.setHandler "campaigns:sync", ->
    API.syncCampaigns()

  App.commands.setHandler "campaigns:user:clear", ->
    API.clear()

  App.vent.on "credentials:cleared", ->
    API.clear()

  App.vent.on "campaigns:meta:update", ->
    API.saveLocalCampaigns currentCampaignsUser
