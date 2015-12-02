@Ohmage.module "Entities", ((Entities, App, Backbone, Marionette, $, _, Modernizr) ->

  API =
    initDevice: ->
      myDevice = {}
      myDevice.isNative = App.cordova
      myDevice.isiOS7 = false

      if myDevice.isNative and device.platform is "iOS"
        myDevice.isiOS7 = @isDeviceiOS7Plus()

      @setClientString myDevice

      @detectCSS()
      myDevice

    setClientString: (myDevice) ->
      App.client_string = App.custom.api.client_base_string

      if myDevice.isNative
        App.client_string += device.platform
      else
        App.client_string += 'browser'

    isDeviceiOS7Plus: ->
      version = @getDeviceiOSVersion()
      version[0] >= 7

    getDeviceiOSVersion: ->
      v = (navigator.appVersion).match(/OS (\d+)_(\d+)_?(\d+)?/)
      [ parseInt(v[1], 10), parseInt(v[2], 10), parseInt(v[3] or 0, 10) ]

    detectCSS: ->
      if Modernizr.csstransforms
        $('body').addClass('animated-menu')

  App.reqres.setHandler "device:init", ->
    API.initDevice()

), Modernizr
