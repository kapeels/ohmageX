@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The History Selector Entity is the generic object definition
  # for a single selector dropdown, used for filtering History entries.

  class Entities.UserHistorySelectorNav extends Entities.NavsCollection
    initialize: (models, options) ->

      _.defaults options,
        defaultLabel: "All"

      # filterType is the property of Entries
      # to use to filter the unique contents of the dropdown.
      @filterType = options.filterType

      @defaultLabel = options.defaultLabel

      @entries = models

      # only create these listeners if entries is an actual Collection.
      if @entries instanceof Entities.UserHistoryEntries
        @listenTo @entries, "sync:stop reset", =>
          @reset @entries, parse: true

    parse: (entries) ->

      # prepend default label.
      result = [
            name: @defaultLabel
          ]

      if @entries? and @entries.length > 0 and @entries instanceof Entities.UserHistoryEntries
        # get an array that contains only unique filters.
        # pass `true` for isSorted param of `uniq` to speed it up.
        uniqueSurveys = _.chain(entries.toJSON()).pluck(@filterType).uniq(false).value()
        result = result.concat uniqueSurveys.map (filterType) =>
          return {
            name: filterType
          }

      result

    chosenName: ->
      (@findWhere(chosen: true) or @first()).get('name')
