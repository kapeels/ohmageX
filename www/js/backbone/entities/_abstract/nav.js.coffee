@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Nav extends Entities.Model
    isDivider: -> @get('divider')

    isChosen: -> @get('chosen')

    choose: ->
      @set chosen: true

    unchoose: ->
      @set chosen: false
 
    chooseByCollection: ->
      @collection.choose @

  class Entities.NavsCollection extends Entities.Collection
    model: Entities.Nav

    choose: (model) ->
      _(@where chosen: true).invoke("unchoose")
      model.choose()

    chooseByName: (nav) ->
      @choose (@findWhere(name: nav) or @first())

    getSelectedName: ->
      if @findWhere(chosen: true)
        @findWhere(chosen: true).get('name')
      else
        false

    getUrlByName: (myName) ->
      @findWhere(name: myName).get('url')

    setMarker: (name, value) ->
      if @findWhere(name: name)
        @findWhere(name: name).set('marker', value)

  API =
    reveal: (isLoggedIn) ->
      console.log 'reveal isLoggedIn', isLoggedIn
      if isLoggedIn
        loginItems = [
          "dashboardeqis"
          "campaign"
          "history"
          "survey"
          "queue"
          "reminder"
          "profile"
          "logout"
        ]
        if App.custom.build.debug
          filterItems = []
        else if App.device.isNative
          filterItems = App.custom.menu_items_disabled.native
        else
          filterItems = App.custom.menu_items_disabled.browser

        visibleItems = _.difference(loginItems, filterItems)
      else
        visibleItems = [
          "login"
        ]
      App.navs.each((nav) ->
        visible = nav.get('name') in visibleItems
        nav.set 'visible', visible
      )
      App.navs.trigger "reveal"

    getNavs: ->
      App.navs = new Entities.NavsCollection [
        { name: "login", url: "#login", icon: "profile", visible: false, marker: false }
        { name: "dashboardeqis", url: "#dashboard", icon: "survey", visible: false, marker: false }
        { name: "campaign", url: "#campaigns", icon: "campaign", visible: false, marker: false }
        { name: "survey", url: "#surveys", icon: "survey", visible: false, marker: false }
        { name: "queue", url: "#uploadqueue", icon: "upload", visible: false, marker: false }
        { name: "history", url: "#history", icon: "history", visible: false, marker: false }
        { name: "reminder", url: "#reminders", icon: "reminder", visible: false, marker: false }
        { name: "profile", url: "#profile", icon: "profile", visible: false, marker: false }
        { name: "logout", url: "#logout", icon: "logout", visible: false, marker: false }
      ]

  App.vent.on "credentials:storage:load:success credentials:storage:load:failure", ->
    API.reveal App.request("credentials:isloggedin")

  App.reqres.setHandler "nav:entities", ->
    API.getNavs()

  App.vent.on "credentials:cleared", ->
    API.reveal false

  App.vent.on "credentials:validated", ->
    API.reveal true
