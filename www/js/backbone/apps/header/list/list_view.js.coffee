@Ohmage.module "HeaderApp.List", (List, App, Backbone, Marionette, $, _) ->

  class List.Nav extends App.Views.ItemView
    initialize: ->
      @listenTo @, "raw:click", ->
        if @model.isChosen()
          @trigger "chosen:clicked"
        else
          @trigger "chosen:check"

    tagName: "li"

    modelEvents:
      "change:chosen": "changeChosen"
      "change:marker": "render"

    getTemplate: -> 
      if @model.isDivider() then false else "header/list/_nav"

    onRender: ->
      @$el.addClass "divider" if @model.isDivider()

    attributes: ->
      # TODO: Replace inline style with proper style
      # Attempted using ".hide" and "data-visible=[false]"
      # but both were exceeded in precedence by other selectors
      if @model.get('visible') is false then {style: "display: none !important"} else {}

    changeChosen: (model, value, options) ->
      @$el.toggleClass "active", value

    triggers:
      "click": "raw:click"
    serializeData: ->
      data = @model.toJSON()
      data.navLabel = App.dictionary "menu", @model.get('name')
      data

  class List.Title extends App.Views.ItemView
    tagName: "span"
    template: "header/list/_title"

    collectionEvents: ->
      "change:marker": "render"

    serializeData: ->
      chosenModel = @collection.findWhere(chosen: true)
      data = {}
      if chosenModel is undefined 
        data.pageTitle = App.package_info.app_name
      else
        name = chosenModel.get("name")
        data.pageTitle = App.dictionary "menu", name
        data.icon = chosenModel.get("icon")
        data.marker = chosenModel.get("marker")
      data

  class List.Header extends App.Views.CollectionView
    initialize: ->
      @listenTo @collection, "reveal", @render
      @listenTo @, "childview:chosen:check", @chosenCheck
      @listenTo @, "childview:chosen:clicked", (-> @collection.trigger "chosen:canceled")
    chosenCheck: (args) ->
      myName = args.model.get('name')
      myUrl = args.model.get('url')

      surveyActive = App.request "surveytracker:active"
      logoutChosen = myName is "logout"

      showDialog = surveyActive or logoutChosen
      saveLocation = if App.device.isNative then "on this device" else "on this web browser"

      if showDialog
        if surveyActive and logoutChosen
          message = "Data from your current #{App.dictionary('page','survey')} response will be lost, and any data saved #{saveLocation} will be lost. Do you want to logout and exit the #{App.dictionary('page','survey')}?"
        else if surveyActive
          message = "Data from your current #{App.dictionary('page','survey')} response will be lost. Do you want to exit the #{App.dictionary('page','survey')}?"
        else if logoutChosen
          message = "Do you want to logout? Any data saved #{saveLocation} will be lost."

        App.execute "dialog:confirm", message, (=>
          # reset active survey's entities.
          if surveyActive then App.vent.trigger "survey:reset"
          App.navigate myUrl, { trigger: true }
        ),(=>
          @collection.trigger "chosen:canceled"
        )
      else
        App.navigate myUrl, { trigger: true }

    tagName: "ul"
    attributes:
      class: "right"
    childView: List.Nav

  class List.Layout extends App.Views.Layout
    initialize: ->
      @listenTo @collection, "change:chosen", (model) ->
        if model.isChosen()
          @menu.close()
          # TODO: Clean this up - perhaps fetch all nav icon values
          # and remove all associated classnames
          @$el.removeClass 'profile'
          @$el.removeClass 'campaign'
          @$el.removeClass 'history'
          @$el.removeClass 'survey'
          @$el.removeClass 'upload'
          @$el.removeClass 'reminder'
          @$el.addClass model.get('icon')
      @listenTo @collection, "chosen:canceled", ->
        @menu.close()

      @listenTo App.vent, "external:hamburgermenu:close", ->
        if $('body').attr('slideout-state') is 'active'
          @menu.close()

    template: "header/list/layout"
    attributes: ->
      if App.device.isiOS7 then { class: "ios7" }
    regions:
      listRegion: "#app-menu .list-container"
      buttonRegion: "#button-region"
      titleRegion: "#page-title"
    onRender: ->
      triggerEvent = if App.device.isNative then 'touchstart' else 'click'
      @menu = new SlideOutComponent('#app-menu', @$el, triggerEvent)
      @menu.toggleOn('.app-menu-trigger', @$el)
