@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The upload Queue Entity deals with data relating to the upload Queue.

  currentQueue = false

  class Entities.UploadQueueItem extends Entities.Model
    defaults: ->
      return {
        timestamp: (new Date).getTime() # new items get the epoch time
        status: 'running' # All queue items are running unless otherwise
      }

  class Entities.UploadQueue extends Entities.Collection
    model: Entities.UploadQueueItem
    comparator: (item) ->
      -(item.get 'timestamp')
    initialize: (options) ->
      @listenTo @, "add remove", =>
        if @length isnt 0
          App.execute "nav:marker:set", "queue", "(#{@length})"
        else
          App.execute "nav:marker:set", "queue", false

  API =
    init: ->
      App.request "storage:get", 'upload_queue', ((result) =>
        # user upload queue retrieved from raw JSON.
        console.log 'user upload queue retrieved from storage'
        currentQueue = new Entities.UploadQueue result
        if currentQueue.length > 0
          App.execute "nav:marker:set", "queue", "(#{currentQueue.length})"
      ), =>
        console.log 'user upload queue not retrieved from storage'
        currentQueue = new Entities.UploadQueue

    addItem: (responseData, errorText, responses, surveyId) ->
      console.log 'addItem responseData', responseData

      surveyObj = JSON.parse responseData.surveys
      console.log 'surveyObj', surveyObj
      result =
        data: responseData
        timestamp: responseData.timestamp
        campaign_name: App.request "campaign:name", responseData.campaign_urn
        campaign_urn: responseData.campaign_urn
        campaign_creation_timestamp: responseData.campaign_creation_timestamp
        name: App.request('survey:saved:title', surveyId)
        description: App.request('survey:saved:description', surveyId)
        id: _.guid()
        errorText: errorText
        responses: responses
        uploadType: App.request 'responses:uploadtype'

      if surveyObj[0].location_status is "valid"
        _.extend(result, location: surveyObj[0].location)

      if result.uploadType is 'video' or result.uploadType is 'file'
        _.extend result,
          fileMeta:
            firstFile: App.request "survey:files:first:file"
            firstUUID: App.request "survey:files:first:uuid"
            surveyFiles: App.request "survey:files"

      currentQueue.add result
      @updateLocal( =>
        App.vent.trigger 'uploadqueue:add:success', result
      )

    removeItem: (id) ->
      currentQueue.remove currentQueue.get(id)
      @updateLocal( =>
        App.vent.trigger 'uploadqueue:remove:success', id
      )
    changeError: (id, errorText) ->
      console.log 'changeError id', id
      queueItem = currentQueue.get id
      queueItem.set 'errorText', errorText
      @updateLocal( =>
        App.vent.trigger 'uploadqueue:change:error:success', id
      )
    updateLocal: (callback) ->
      # update localStorage index upload_queue with the current version of campaignsSaved entity
      App.execute "storage:save", 'upload_queue', currentQueue.toJSON(), callback
    getUploadType: (id) ->
      queueItem = currentQueue.get id
      console.log 'queueItem', queueItem.toJSON()
      queueItem.get 'uploadType'
    getFileMeta: (id) ->
      queueItem = currentQueue.get id
      queueItem.get 'fileMeta'
    clear: ->
      currentQueue = new Entities.UploadQueue

      App.execute "storage:clear", 'upload_queue', ->
        console.log 'user upload queue erased'
        App.vent.trigger "uploadqueue:cleared"

  App.on "before:start", ->
    API.init()

  App.commands.setHandler "uploadqueue:item:add", (responseData, errorText, surveyId) ->
    responses = App.request 'responses:current:flow'
    API.addItem responseData, errorText, responses, surveyId

  App.commands.setHandler "uploadqueue:item:remove", (id) ->
    API.removeItem id

  App.reqres.setHandler 'uploadqueue:item:uploadtype', (id) ->
    API.getUploadType id

  App.reqres.setHandler "uploadqueue:item:surveyfiles", (id) ->
    files = API.getFileMeta id
    files.surveyFiles

  App.reqres.setHandler "uploadqueue:item:firstfile", (id) ->
    files = API.getFileMeta id
    files.firstFile

  App.reqres.setHandler "uploadqueue:item:firstuuid", (id) ->
    files = API.getFileMeta id
    files.firstUUID

  App.commands.setHandler "uploadqueue:item:error:set", (id, errorText) ->
    API.changeError id, errorText

  App.reqres.setHandler "uploadqueue:entity", ->
    currentQueue

  App.reqres.setHandler "uploadqueue:item", (id) ->
    if !!!currentQueue.get(id) then throw new Error "item id #{id} does not exist in upload queue"
    currentQueue.get(id)

  App.reqres.setHandler "uploadqueue:length", ->
    currentQueue.length

  App.commands.setHandler "uploadqueue:clear", ->
    API.clear()

  App.vent.on "credentials:cleared", ->
    API.clear()

  App.vent.on "survey:upload:failure:auth", (responseData, errorText, surveyId) ->
    if !App.request("credentials:ispassword")
      # dump to queue and save survey
      App.execute "uploadqueue:item:add", responseData, "#{errorPrefix} #{errorText}", surveyId
