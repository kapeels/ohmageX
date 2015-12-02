@Ohmage.module "Components.Prompts", (Prompts, App, Backbone, Marionette, $, _) ->

  class Prompts.Photo extends Prompts.Base
    template: "prompts/photo"
    triggers: ->
      if App.device.isNative
        return {
          'click .input-activate .get-photo': "take:picture"
          'click .input-activate .take-picture': "take:picture"
          'click .input-activate .from-library': "from:library"
        }
      else
        return 'change input[type=file]': "file:changed"

    initialize: ->
      super
      @listenTo @, "file:changed", @processFile
      @listenTo @, "take:picture", @takePicture
      @listenTo @, "from:library", @fromLibrary

    serializeData: ->
      data = @model.toJSON()
      # only show a single button in the browser, or on iPad
      # (iPad shows a popover that allows the user to select a picture)
      data.showSingleButton = !App.device.isNative or 
        (device.platform is "iOS" and device.model.indexOf('iPad') isnt -1)
      data

    constrainMaxDimension: ->
      maxDimension = @model.get('properties').get('maxDimension')
      if "#{maxDimension}" is "0"
        # When maxDimension is 0, assume there is no max dimension
        maxDimension = 99999
      else
        if !!!maxDimension then maxDimension = App.custom.prompt_defaults.photo.max_pixels

      if App.device.isNative
        # on some devices a max dimension larger than 800 may cause memory errors.
        # Added support for max 1600, but note that devices with high resolution
        # cameras may still crash on resolutions greater than 800. Recommended
        # max 800 unless absolutely necessary.
        if maxDimension > 1600 then maxDimension = 1600

      maxDimension

    processFile: ->
      fileDOM = @$el.find('input[type=file]')[0]
      myInput = fileDOM.files[0]
      _URL = window.URL || window.webkitURL
      maxDimension = @constrainMaxDimension()

      img = new Image()
      imgCanvas = @$el.find('canvas')[0]

      if myInput
        if myInput.type in ['image/jpeg','image/png']
          img.onload = =>
            # resize image if exceeds max dimension
            if img.width > maxDimension or img.height > maxDimension
              ratio = Math.min(maxDimension / img.width, maxDimension / img.height)
              img.width = img.width * ratio
              img.height = img.height * ratio
            # place image on canvas, base64 encode
            context = imgCanvas.getContext('2d')
            context.clearRect 0, 0, imgCanvas.width, imgCanvas.height
            imgCanvas.width = img.width
            imgCanvas.height = img.height
            context.drawImage img, 0, 0, img.width, img.height
            @recordImage imgCanvas.toDataURL('image/jpeg', 0.45)
            _URL.revokeObjectURL(img.src)

          img.src = _URL.createObjectURL myInput
        else
          console.log 'Please upload an image in jpeg or png format.'
      else
        console.log 'Please select an image.'

    takePicture: ->
      @getPicture navigator.camera.PictureSourceType.CAMERA

    fromLibrary: ->
      @getPicture navigator.camera.PictureSourceType.PHOTOLIBRARY

    getPicture: (source) ->
      # Device camera plugin, get picture and retrieve image as base64-encoded string
      console.log 'getMobileImage method'
      maxDimension = @constrainMaxDimension()

      navigator.camera.getPicture ((img64) =>
        # success callback
        @recordImage "data:image/jpeg;base64,#{img64}"

      ),((message) =>
        # error callback
        window.setTimeout (=>
          # setTimeout hack required to display alerts properly in iOS camera callbacks
          App.execute "dialog:alert", "Failed to get image: #{message}"
        ), 0
      ),
        quality: 45
        allowEdit: false
        destinationType: navigator.camera.DestinationType.DATA_URL
        sourceType: source
        targetWidth: maxDimension
        targetHeight: maxDimension

    recordImage: (img64) ->
      @model.set('currentValue', img64)
      @renderImageThumb img64

    renderImageThumb: (img64) ->
      # display the image in the preview
      $img = @$el.find '.preview-image'
      $img.prop 'src', img64
      $img.css 'display', 'block'

    onRender: ->
      savedImage = @model.get('currentValue')
      if savedImage then @renderImageThumb(savedImage)
      if App.device.isNative
        # hide the input button on native so the "Get Photo"
        # button beneath it can activate
        @$el.find('.input-activate input').hide()

    gatherResponses: (surveyId, stepId) =>
      response = @model.get('currentValue')
      @trigger "response:submit", response, surveyId, stepId
