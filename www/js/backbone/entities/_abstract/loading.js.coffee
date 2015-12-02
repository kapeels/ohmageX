@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Loading extends Entities.Model
    defaults:
      message: 'Now Loading...'
    timer: false
    loadShow: (message = false, options = {}) ->
      _.defaults options,
        instant: false

      { instant } = options

      if message isnt false then @set('message', message)
      if @timer then window.clearTimeout(@timer)
      if instant
        @trigger 'loading:show'        
      else
        # loading spinner uses a delay timer.
        # if a task finishes quickly, it won't
        # disruptively flash the loading spinner.
        @timer = window.setTimeout (=>
          @trigger 'loading:show'
        ), 250

    loadHide: ->
      @set 'message', 'Now Loading...'
      @trigger 'loading:hide'
      window.clearTimeout @timer
      @timer = false
    loadUpdate: (message) ->
      @set 'message', message
      @trigger 'loading:update', message

  API =
    getLoading: (message) ->
      new Entities.Loading message: message

  App.reqres.setHandler "loading:entities", ->
    API.getLoading()
