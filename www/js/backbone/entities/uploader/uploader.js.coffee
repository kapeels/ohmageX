@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This Entity handles upload processing for responses.

  class Entities.Uploader extends Entities.Model

  API =
    parseUploadErrors: (context, responseData, response, itemId) ->
      console.log 'parseUploadErrors'
      if response.result is "success"
        console.log 'Uploader Success!'
        App.vent.trigger "loading:hide"
        if context is 'uploadqueue' then App.vent.trigger("uploadtracker:complete")
        App.vent.trigger "#{context}:upload:success", response, itemId
      else
        console.log "response.errors[0].code #{response.errors[0].code}"
        type = switch response.errors[0].code
          when '0710','0703','0617','0700' then "campaign"
          when '0100' then "server"
          when '0600','0307','0302','0304','0314' then "response"
          when '0200','0201','0202' then "auth"
          else "server"
        console.log 'type', type
        if context isnt 'uqall' then App.vent.trigger("uploadtracker:complete")
        App.vent.trigger "loading:hide"
        App.vent.trigger "#{context}:upload:failure:#{type}", responseData, response.errors[0].text, itemId

    ajaxUploader: (context, responseData, itemId) ->

      # add auth credentials to the response before saving.
      # may later move this to the model's custom "sync" method.
      myAuth = App.request 'credentials:upload:params'
      throw new Error "Authentication credentials not set in uploader" if myAuth is false

      # uploader = new Entities.Uploader _.extend(myAuth, responseData)

      # Uses $.ajax() instead of Backbone.save() because of server error.
      # See Issue #208


      $.ajax
        type: 'POST' # not RESTful but the Ohmage 2.0 API requires it
        data: _.extend(myAuth, responseData)
        url: "#{App.request("serverpath:current")}/app/survey/upload"
        dataType: 'json'
        success: (response) =>
          @parseUploadErrors context, responseData, response, itemId
        error: (xhr, ajaxOptions, thrownError) =>
          console.log 'survey upload error'
          # assume all error callbacks here are network relate
          if context isnt 'uqall' then App.vent.trigger("uploadtracker:complete")
          App.vent.trigger "loading:hide"
          App.vent.trigger "#{context}:upload:failure:network", responseData, xhr.status, itemId

    documentUploader: (context, responseData, itemId) ->
      App.vent.trigger "loading:show", "Uploading ...", instant: true

      # add auth credentials to the response before saving.
      # may later move this to the model's custom "sync" method.
      myAuth = App.request 'credentials:upload:params'
      throw new Error "Authentication credentials not set in uploader" if myAuth is false

      ###
      xhr = new XMLHttpRequest()
      xhr.upload.addEventListener 'progress',( (ev) =>
        App.vent.trigger "loading:show", "Uploading #{Math.round(ev.loaded / ev.total * 100)}%..."
      ), false

      xhr.upload.addEventListener 'loadend', (=> App.vent.trigger "loading:hide")

      xhr.onreadystatechange = (evt) =>
        if xhr.readyState is 4
          if xhr.status is 200
            @parseUploadErrors context, responseData, xhr.response, itemId
          else
            console.log 'survey upload error'
            # assume all error callbacks here are network relate
            App.vent.trigger "#{context}:upload:failure:network", responseData, xhr.upload.status, itemId

      myData = @xhrFormData _.extend(myAuth, responseData, App.request("survey:files"))

      xhr.open 'POST', "#{App.request("serverpath:current")}/app/survey/upload", true
      xhr.responseType = "json"
      xhr.setRequestHeader "Content-Type","multipart/form-data"
      xhr.send myData
      ###

      if context is 'survey'
        surveyFiles = App.request("survey:files")
      else
        surveyFiles = App.request "uploadqueue:item:surveyfiles", itemId
      console.log 'surveyFiles', surveyFiles

      myData = @xhrFormData _.extend(myAuth, responseData, surveyFiles)

      $.ajax
        url: "#{App.request("serverpath:current")}/app/survey/upload"
        data: myData
        cache: false
        contentType: false
        processData: false
        type: "POST"
        xhr: =>
          # customize XMLHttpRequest
          myXhr = $.ajaxSettings.xhr()
          if myXhr.upload
            myXhr.upload.addEventListener 'progress',( (ev) =>
              if ev.lengthComputable
                App.vent.trigger "loading:show", "Uploading #{Math.round(ev.loaded / ev.total * 100)}%..."
            ), false
          myXhr
        success: (response) =>
          @parseUploadErrors context, responseData, response, itemId
        error: (xhr, ajaxOptions, thrownError) =>
          console.log 'survey upload error'
          # assume all error callbacks here are network relate
          App.vent.trigger "loading:hide"
          if context isnt 'uqall' then App.vent.trigger("uploadtracker:complete")
          App.vent.trigger "#{context}:upload:failure:network", responseData, xhr.status, itemId

    xhrFormData: (responseObj) ->
      console.log 'xhrFormData responseObj', responseObj

      myData = new FormData()
      _.each responseObj, (value, key) ->
        # set all properties using the FormData API, including files
        if key is 'surveys'
          # surveys requires the JSON to be formatted as a Blob 
          survey_blob = new Blob([value], {type: 'application/json'})
          myData.append key, survey_blob
        else
          myData.append key, value

      myData

    videoUploader: (context, responseData, itemId) ->
      # we're currently assuming there is only one video file per upload at this time.
      App.vent.trigger "loading:show", "Uploading ...", instant: true

      # add auth credentials to the response before saving.
      # may later move this to the model's custom "sync" method.
      myAuth = App.request 'credentials:upload:params'
      throw new Error "Authentication credentials not set in uploader" if myAuth is false


      uri = encodeURI("#{App.request("serverpath:current")}/app/survey/upload")
      options = new FileUploadOptions()

      if context is 'survey'
        firstFile = App.request("survey:files:first:file")
        firstUUID = App.request("survey:files:first:uuid")
      else
        firstFile = App.request "uploadqueue:item:firstfile", itemId
        firstUUID = App.request "uploadqueue:item:firstuuid", itemId

      console.log "firstFile #{JSON.stringify(firstFile)}"
      options.fileName = firstFile.name
      options.mimeType = firstFile.type
      # iOS returns null for video file type.
      # Set the MIME type to mp4 so the server accepts the upload,
      # since it's assumed that all iOS videos will be of this type.
      if firstFile.type is null then options.mimeType = "video/mp4"
      options.fileKey = firstUUID
      options.params = @videoParams _.extend(myAuth, responseData)

      console.log "file upload options: #{JSON.stringify(options)}"

      ft = new FileTransfer()
      ft.onprogress = (progressEvent) =>
        if progressEvent.lengthComputable
          App.vent.trigger "loading:show", "Uploading #{Math.round(progressEvent.loaded / progressEvent.total * 100)}%..."

      ft.upload firstFile.localURL, uri, ( (uploadResult) =>
        # upload success callback - returns a FileUploadResult obj
        # properties: bytesSent, responseCode, response

        console.log "upload complete #{JSON.stringify(uploadResult)}"
        @parseUploadErrors context, responseData, JSON.parse(uploadResult.response), itemId

      ), ( (error) =>
        # upload error callback - returns a FileTransferError obj
        # code
        console.log 'survey upload error'
        # assume all error callbacks here are network relate
        if context isnt 'uqall' then App.vent.trigger("uploadtracker:complete")
        App.vent.trigger "loading:hide"

        switch error.code
          when FileTransferError.CONNECTION_ERR
            App.vent.trigger "#{context}:upload:failure:network", responseData, "Connection Issue", itemId
          when FileTransferError.FILE_NOT_FOUND_ERR
            App.vent.trigger "#{context}:upload:failure:response", responseData, "Response file not found", itemId
          when FileTransferError.INVALID_URL_ERR
            App.vent.trigger "#{context}:upload:failure:network", responseData, "Server could not be reached", itemId
          when FileTransferError.ABORT_ERR
            App.vent.trigger "#{context}:upload:failure:abort", responseData, "Try again?", itemId

      ), options

    videoParams: (responseObj) ->
      params = {}
      _.each responseObj, (value, key) ->
        params[key] = value

  App.commands.setHandler "uploader:new", (context, responseData, itemId) ->
    # context is a means of determining the 
    # execution context of the `uploader:new` command.
    # 'survey' - it's launched from a survey context.
    # 'uploadqueue' - it's launched from the upload queue.

    # itemId
    # in a 'survey' context, this is a reference to the surveyId.
    # in an 'uploadqueue' context, this is a reference to the queue item's
    # model id.
    App.vent.trigger "loading:show", "Submitting #{App.dictionary('page','survey').capitalizeFirstLetter()}..."

    if context is 'survey'
      uploadType = App.request "responses:uploadtype"
    else
      uploadType = App.request 'uploadqueue:item:uploadtype', itemId

    # on device, no wifi and user preference set to only upload on wifi 
    cellNetworkTypes = [Connection.CELL, Connection.CELL_2G, Connection.CELL_3G, Connection.CELL_4G] if App.device.isNative
    if App.device.isNative and navigator.connection.type in cellNetworkTypes and App.request("user:preferences:get", 'wifi_upload_only')
      console.log "device not on wifi, user preferences requires for upload."
      App.vent.trigger "#{context}:upload:failure:wifionly", responseData, "Not on WiFi", itemId
      App.vent.trigger "loading:hide"

    else # continue with upload in all other cases.
      console.log 'uploadType', uploadType
      App.vent.trigger "uploadtracker:active"
  
      switch uploadType
        when 'video'
          API.videoUploader context, responseData, itemId
        when 'file'
          API.documentUploader context, responseData, itemId
        else
          API.ajaxUploader context, responseData, itemId
