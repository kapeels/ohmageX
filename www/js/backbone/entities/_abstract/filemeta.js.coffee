@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The FileMeta entity stores meta information about stored files on the device.
  # Currently the File Meta store does not erase on logout like other components.
  # Only the user can erase it.

  class Entities.FileMetaEntry extends Entities.Model

  class Entities.FileMeta extends Entities.Collection
    model: Entities.FileMetaEntry


  storedMeta = false
  # prefix string added to all auto fetch requests
  autoPrefix = "auto:"

  API =
    init: ->
      App.request "storage:get", 'file_meta', ((result) =>
        console.log 'saved file meta retrieved from storage'
        storedMeta = new Entities.FileMeta result
        App.vent.trigger "filemeta:saved:init:success"
      ), =>
        console.log 'saved file meta not retrieved from storage'
        storedMeta = new Entities.FileMeta
        App.vent.trigger "filemeta:saved:init:failure"

    getFileMetaLength: ->
      storedMeta.length

    generateMediaURL: (uuid, context) ->

      if context.indexOf(autoPrefix) is 0
        # if the context string contains the "auto" prefix, remove the prefix.
        context = context.substring autoPrefix.length

      myData =
        client: App.client_string
        id: uuid
      myData = _.extend(myData, App.request("credentials:upload:params"))

      myURL = "#{App.request("serverpath:current")}/app/#{context}/read?#{$.param(myData)}"
      myURL

    removeFileMeta: (id) ->
      storedMeta.remove storedMeta.get(id)
      @updateLocal( =>
        console.log "file meta API.removeFileMeta storage success"
      )

    addFileMeta: (options) ->
      storedMeta.add options
      @updateLocal( =>
        console.log "file meta API.addFileMeta storage success"
      )

    updateLocal: (callback) ->
      # update localStorage index file_meta with the current version of the file meta store
      App.execute "storage:save", 'file_meta', storedMeta.toJSON(), callback

    deleteReference: (uuid) ->
      # delete any saved file reference if it already exists.

      if storedMeta.where(id: uuid)
        App.execute "system:file:uuid:remove", uuid
        @removeFileMeta uuid

    fetchMedia: (uuid, context) ->

      App.execute "system:file:uuid:read",
        uuid: uuid
        success: (fileEntry) =>
          switch (context)
            when 'image'
              App.vent.trigger "file:image:url:success", uuid, fileEntry.toURL()
            when 'media'
              App.vent.trigger "file:media:open:complete"
              fileEntry.file (file) =>
                console.log "fileEntry file", file
                App.execute "system:file:uuid:open", uuid, file.type
            else
              # auto download queue
              # It exists - the file doesn't have to be
              # downloaded at all! Just trigger success to resolve
              # this queue item.
              App.vent.trigger "filemeta:fetch:auto:success", uuid, context
        error: (message) =>
          console.log 'error reading file: ', message
          @deleteReference uuid

          # file wasn't read, try to download it.
          switch (context)
            when 'image'
              App.vent.trigger "file:image:uuid:notfound", uuid
              @downloadMedia uuid, context
            when 'media'
              if navigator.connection.type is Connection.NONE
                # they're offline.
                App.execute "dialog:alert", "Unable to open file on the device, try again when a network is available."
                return false

              App.vent.trigger "file:media:uuid:notfound", uuid
              App.execute "dialog:confirm", "Download and open the file? It may be large and take a long time to download.", (=>
                @downloadMedia uuid, context
              ), (=>
                console.log 'dialog canceled'
              )
            else
              # it's automatic, attempt to download with no prompts
              @downloadMedia uuid, context


    downloadMedia: (uuid, context) ->
      App.execute "system:file:uuid:download",
        uuid: uuid
        url: @generateMediaURL(uuid, context)
        showLoader: context in ['image','media'] # only show the loader for image and media downloads, not auto
        success: (fileEntry) =>
          switch (context)
            when 'image'
              App.vent.trigger "file:image:url:success", uuid, fileEntry.toURL()
            when 'media'
              App.vent.trigger "file:media:open:complete"
              fileEntry.file (file) =>
                App.execute "system:file:uuid:open", uuid, file.type
            else
              # resolve the queue item, download succeeded
              App.vent.trigger "filemeta:fetch:auto:success", uuid, context

          # add a file meta entry in all cases
          @addFileMeta
            id: uuid
            username: App.request("credentials:username")

        error: =>
          switch (context)
            when 'image'
              App.vent.trigger "file:image:url:error", uuid
            when 'media'
              App.vent.trigger "file:media:open:error", uuid
            else
              # resolve the queue item with an error, download failed
              App.vent.trigger "filemeta:fetch:auto:error", uuid, context

    clear: ->

      # erase all stored file entries one at a time.
      storedMeta.each (fileMetaEntry) =>
        # don't need to pass callbacks to removal. Removal just happens in the background.
        App.execute "system:file:uuid:remove", fileMetaEntry.get('id')

      storedMeta = new Entities.FileMeta

      App.execute "storage:clear", 'file_meta', ->
        console.log 'file meta erased'
        App.vent.trigger "filemeta:saved:cleared"

    moveMedia: (callback) ->
      if App.request("responses:uploadtype") is 'video'
        uuid = App.request("survey:files:first:uuid")
        App.vent.trigger "filemeta:move:native:start"
        App.execute "system:file:uuid:move", uuid, App.request("survey:files:first:file"), callback
      else
        callback()

  App.on "before:start", ->
    API.init()

  App.commands.setHandler "filemeta:erase:all", ->
    metaLength = API.getFileMetaLength()
    if metaLength > 0
      App.execute "dialog:confirm", "Are you sure you want to clear the file cache? You will lose #{metaLength} file(s).", (=>
        API.clear()
      ), (=>
        console.log 'dialog canceled'
      )

  App.commands.setHandler "filemeta:add:entry", (uuid) ->
    API.addFileMeta
      id: uuid
      username: App.request("credentials:username")

  App.commands.setHandler "filemeta:fetch:image:url", (uuid) ->
    API.fetchMedia uuid, 'image'

  App.commands.setHandler "filemeta:fetch:media:open", (uuid) ->
    API.fetchMedia uuid, 'media'

  App.commands.setHandler "filemeta:fetch:auto", (uuid, context) ->
    API.fetchMedia uuid, "#{autoPrefix}#{context}"

  App.commands.setHandler "filemeta:move:native", (callback) ->
    if App.device.isNative
      API.moveMedia callback
    else
      callback()

  App.vent.on "filemeta:move:native:start", ->
    App.vent.trigger "loading:show", "Preparing Upload..."

  App.vent.on "filemeta:read:complete", ->
    App.vent.trigger "loading:hide"

  App.vent.on "filemeta:read:success", (file) ->
    console.log 'filemeta:read:success', file

  App.vent.on "filemeta:read:error:notfound", (fileName) ->
    App.execute "dialog:alert", "The selected file \"#{fileName}\" could not be found. Please select another file."

  App.vent.on "filemeta:read:error:unreadable", (fileName) ->
    App.execute "dialog:alert", "The selected file \"#{fileName}\" was unreadable. Please select another file."

