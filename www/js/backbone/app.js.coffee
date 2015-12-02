@Ohmage = do (Backbone, Marionette) ->

  App = new Marionette.Application


  App.on "before:start", (options) ->
    App.environment = options.environment
    App.version = options.app_version
    App.cordova = options.cordova
    App.custom = options.app_config
    App.device = App.request "device:init"
    App.credentials = false
    App.navs = App.request "nav:entities"
    App.loading = App.request "loading:entities"
    App.package_info = options.package_info

    # overwrite base config with custom build options
    defaultUrl = App.navs.getUrlByName App.custom.routes.homepage
    Routes.dashboard_route = -> defaultUrl

  App.addRegions
    loadingRegion: "body > #loading-spinner"
    blockerRegion: "body > #ui-blocker"
    fullModalRegion: "body > #full-modal"
    headerRegion: "body > header"
    mainRegion:    "body > main"
    footerRegion: "body > footer"

  App.rootRoute = Routes.default_route()

  App.addInitializer ->
    App.module("LoadingspinnerApp").start(App.loading)
    App.module("HeaderApp").start(App.navs)
    App.module("FooterApp").start(App.navs)

  App.reqres.setHandler "default:region", ->
    console.log "default:region"
    App.mainRegion

  App.vent.on "nav:choose", (nav) -> App.navs.chooseByName nav

  App.vent.on "loading:show", (message, options) -> App.loading.loadShow(message, options)
  App.vent.on "loading:hide", -> App.loading.loadHide()
  App.vent.on "loading:update", (message) -> App.loading.loadUpdate(message)

  App.on "start", ->
    @startHistory()
    App.rootRoute = if @request("credentials:isloggedin") then Routes.dashboard_route() else Routes.default_route()
    @navigate(@rootRoute, trigger: true) unless @getCurrentRoute()

    if !App.device.isNative
      window.onbeforeunload = ->
        if App.request "surveytracker:active"
          return 'Are you sure you want to leave the Survey Taking tool?'

  App
