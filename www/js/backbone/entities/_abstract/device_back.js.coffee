@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # general handler for device back button. Used for any device
  # that includes a hardware back button (not a browser back button)

  backOverwrite = false

  API =
    init: ->
      if App.device.isNative
        document.addEventListener 'backbutton', ( =>
          @backButtonListener()
        )
      else if App.custom.build.debug is true
        # make the "`" key simulate a device back button during debugging
        $(document).on 'keyup', (e) =>
          # ` key is code 192
          if e.which is 192 then @backButtonListener()

      App.vent.on 'device:dialog:alert:show device:dialog:confirm:show', ->
        API.enableOverwrite()

      App.vent.on 'device:dialog:alert:close device:dialog:confirm:close', ->
        API.disableOverwrite()

      App.vent.on 'device:back:button', ->
        App.vent.trigger 'external:blocker:cancel'
        if !App.request("uploadtracker:uploading")
          App.vent.trigger 'external:survey:prev:navigate'
        App.vent.trigger 'external:hamburgermenu:close'

    backButtonListener: ->
      console.log 'device back button activated'

      if !backOverwrite and 
        !App.request("surveytracker:active") and 
        !App.request("uploadtracker:uploading") and 
        !App.request("appstate:hamburgermenu:active") and 
        !App.request("appstate:loading:active")
          # Event hasn't been overwritten,
          # there is no current survey active,
          # the hamburger menu is not open,
          # and the loader / blocker isn't showing.
          # Execute the default handler
          @defaultBackAction()
      else
        App.vent.trigger "device:back:button"

    defaultBackAction: ->
      console.log 'defaultBackAction'
      if App.navs.getSelectedName() is App.custom.routes.homepage or App.navs.getSelectedName() is "login"
        # we're on the homepage or login screen
        console.log 'on the homepage or login screen'
        App.execute "dialog:confirm", "Exit the app?", (=>
          navigator.app.exitApp()
        )
      else if App.navs.getSelectedName() is "queue" and App.getCurrentRoute() isnt null and App.getCurrentRoute().indexOf('/') isnt -1
        # we're in an upload queue item, close the modal.
        App.vent.trigger "fullmodal:close"
      else if App.navs.getSelectedName() is "history" and App.getCurrentRoute() isnt null and App.getCurrentRoute().indexOf('/') isnt -1
        # we're in a history item, close the modal.
        App.vent.trigger "fullmodal:close"
      else
        # just go to the homepage
        console.log 'go to homepage'
        App.navigate App.navs.getUrlByName(App.custom.routes.homepage), trigger: true

    enableOverwrite: ->
      console.log 'overwrite enabled'
      backOverwrite = true

    disableOverwrite: ->
      console.log 'overwrite disabled'
      backOverwrite = false

  App.on "before:start", ->
    API.init()
