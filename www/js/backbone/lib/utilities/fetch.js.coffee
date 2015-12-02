@Ohmage.module "Utilities", (Utilities, App, Backbone, Marionette, $, _) ->

  App.commands.setHandler "when:fetched", (entities, callback) ->
    xhrs = _.chain([entities]).flatten().pluck("_fetch").value()

    if _.isArray(entities)
      xhrs.push(entity._fetch) for entity in entities
    else
      xhrs.push(entities._fetch)

    $.when(xhrs...).done ->
      callback()

  App.commands.setHandler "when:fetched:always", (entities, callback) ->
    xhrs = _.chain([entities]).flatten().pluck("_fetch").value()

    if _.isArray(entities)
      xhrs.push(entity._fetch) for entity in entities
    else
      xhrs.push(entities._fetch)

    $.when(xhrs...).always ->
      callback()
