@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # This Entity provides an interface for interacting with
  # markers on each nav item. The marker provides additional
  # information to a header item, aside from its title.

  App.commands.setHandler "nav:marker:set", (name, value) ->
    App.navs.setMarker(name, value)
