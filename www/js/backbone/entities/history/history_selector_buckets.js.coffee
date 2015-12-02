@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The History Buckets Entity manages the user History selector containing
  # unique buckets

  currentBuckets = false

  class Entities.UserHistoryBucketsNav extends Entities.UserHistorySelectorNav

  API =
    init: ->
      currentBuckets = new Entities.UserHistoryBucketsNav [],
        parse: true
        filterType: 'bucket'
      currentBuckets.chooseByName currentBuckets.defaultLabel

    getBuckets: (entries) ->
      currentBuckets = new Entities.UserHistoryBucketsNav entries,
        parse: true
        filterType: 'bucket'
      currentBuckets

  App.on "before:start", ->
    API.init()

  App.reqres.setHandler "history:selector:buckets", (entries) ->
    API.getBuckets entries
