@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # Systems File extensions filter.
  # Filter for valid and invalid file extensions.

  # whitelist based on file opener plugin.
  extWhitelist = [
    'gif','jpg','jpeg','png', # images
    'txt', # text
    'mpg','mpeg','mpe','mp4','avi','3gp','3gpp','3g2', # video
    'doc','docx', # Word doc
    'pdf', # pdf
    'ppt','pptx', # Powerpoint
    'xls','xlsx', # Excel
    'rtf' # Rich Text format
  ]

  extVideos = [
    'mpg','mpeg','mpe','mp4','avi','3gp','3gpp','3g2' # video
  ]

  extImages = [
    'gif','jpg','jpeg','png' # images
  ]

  API =
    compareExtToArray: (filename, myArr) ->
      fileExt = filename.match(/\.[0-9a-z]+$/i)
      if fileExt is null then return false

      # truncate `.` from the front
      myJustExt = fileExt[0].slice 1

      myJustExt in myArr

    checkFileExt: (filename) ->
      API.compareExtToArray filename, extWhitelist

    checkVideoExt: (filename) ->
      API.compareExtToArray filename, extVideos

    checkImageExt: (filename) ->
      API.compareExtToArray filename, extImages

  App.reqres.setHandler "system:file:name:is:valid", (filename) ->
    API.checkFileExt filename

  App.reqres.setHandler "system:file:name:is:video", (filename) ->
    API.checkVideoExt filename

  App.reqres.setHandler "system:file:name:is:image", (filename) ->
    API.checkImageExt filename

  App.vent.on "system:file:ext:invalid", (fileName) ->
    App.execute "dialog:alert", "The selected file \"#{fileName}\" does not contain a valid file extension. Please select another file."
