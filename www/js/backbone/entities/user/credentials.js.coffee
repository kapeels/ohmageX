@Ohmage.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # The credentials Entity provides an interface for login credentials.


  class Entities.Credentials extends Entities.Model

  API =
    init: ->
      # using hashed password auth
      if @isPasswordAuth()
        App.request "storage:get", 'credentials', ((result) =>
          # credentials is retrieved from raw JSON.
          console.log 'credentials retrieved from storage'
          App.credentials = new Entities.Credentials result
          App.vent.trigger "credentials:storage:load:success"
        ), =>
          console.log 'credentials not retrieved from storage'
          App.credentials = false
          App.vent.trigger "credentials:storage:load:failure"
      else
        App.execute "credentials:token:verify"

    isParsedAuthValid: (response) ->
      response.result isnt "failure"

    getCredentials: ->
      if @isPasswordAuth()
        # for hashed passwored
        if App.credentials isnt false and App.credentials.has('username') then App.credentials else false
      else
        # just return the stored credentials if using token auth.
        App.credentials

    isPasswordAuth: ->
      App.custom.build.debug or App.device.isNative

    validateCredentials: (path, username, password) ->
      App.vent.trigger "loading:show", "logging in as #{username}..."
      $.ajax
        type: "POST"
        url: "#{path}/app/user/auth"
        data:
          user: username
          password: password
          client: App.client_string
        dataType: 'json'
        success: (response) =>
          if @isParsedAuthValid response
            # we don't hide the loading spinner on success, because when a user
            # logs in, their campaigns are fetched immediately and asynchronously.
            # Hiding it here would hide the loading spinner before the campaigns are
            # finished fetching.

            # only hide the loading spinner if the homepage is NOT
            # a page that automatically fetches content (thus requiring a spinner)
            if App.custom.routes.homepage? and !(App.custom.routes.homepage in ["campaign","dashboardqeis"]) then App.vent.trigger "loading:hide"

            App.credentials = new Entities.Credentials
              username: username
              password: response.hashed_password
            App.execute "storage:save", 'credentials', App.credentials.toJSON(), =>
              console.log "credentials entity API.validateCredentials success"
              App.vent.trigger "credentials:validated", username
          else
            App.vent.trigger "credentials:invalidated", response.errors
            App.vent.trigger "loading:hide"
            if response.errors[0].code is "0202"
              # new user who must change their password.
              # set the username before attempting to change the password.
              App.credentials = new Entities.Credentials
                username: username
                password: false
              App.vent.trigger "blocker:password:change",
                successListener: (=>
                  App.vent.trigger "credentials:validated", username
                )

        error: (xhr, textStatus, errorText) ->
          console.log "Error", xhr.responseText, textStatus, xhr.statusText
          App.vent.trigger "credentials:invalidated", [{text: "Network error, please try again later.", code: "9999"}]
          App.vent.trigger "loading:hide"

    updatePassword: (path, password) ->
      App.vent.trigger "loading:show", "Updating password for #{App.credentials.get 'username'}..."
      $.ajax
        type: "POST"
        url: "#{path}/app/user/auth"
        data:
          user: App.credentials.get 'username'
          password: password
          client: App.client_string
        dataType: 'json'
        success: (response) =>
          if @isParsedAuthValid response

            App.credentials = new Entities.Credentials
              username: App.credentials.get 'username'
              password: response.hashed_password
            App.execute "storage:save", 'credentials', App.credentials.toJSON(), =>
              console.log "credentials entity API.updatePassword success"
              App.vent.trigger "credentials:password:update:validated"
          else
            App.vent.trigger "credentials:password:update:invalidated", 'Authentication failed.'
          App.vent.trigger "loading:hide"
        error: ->
          App.vent.trigger "credentials:password:update:invalidated", 'Network error, unable to update password.'
          App.vent.trigger "loading:hide"

    changePassword: (path, oldPassword, newPassword) ->
      App.vent.trigger "loading:show", "Changing password for #{App.credentials.get 'username'}..."
      $.ajax
        type: "POST"
        url: "#{path}/app/user/change_password"
        data:
          user: App.credentials.get 'username'
          password: oldPassword
          new_password: newPassword
          client: App.client_string
        dataType: 'json'
        success: (response) =>
          if @isParsedAuthValid response

            App.credentials = new Entities.Credentials
              username: App.credentials.get 'username'
              password: response.hashed_password
            App.execute "storage:save", 'credentials', App.credentials.toJSON(), =>
              console.log "credentials entity API.validateCredentials success"
              App.vent.trigger "credentials:password:change:validated"
          else
            App.vent.trigger "credentials:password:change:invalidated", response.errors[0].text
          App.vent.trigger "loading:hide"
        error: (xhr, textStatus, errorText) ->
          console.log "Error", xhr.responseText, textStatus, xhr.statusText
          App.vent.trigger "credentials:password:change:invalidated", 'Network error, unable to change password.'
          App.vent.trigger "loading:hide"


    getParams: ->
      if @isPasswordAuth()
        # using hashed password auth.
        if @getCredentials()
          return {
            user: App.credentials.get('username')
            password: App.credentials.get('password')
          }
        else return false
      else
        # using token based auth.
        App.request "credentials:token:param"

    logout: ->
      App.credentials = false

      App.vent.trigger "credentials:cleared"
      App.execute "storage:clear", 'credentials', ->
        console.log 'credentials erased'

  App.on "before:start", ->
    API.init()

  App.reqres.setHandler "credentials:ispassword", ->
    API.isPasswordAuth()

  App.reqres.setHandler "credentials:isloggedin", ->
    !!API.getCredentials()

  App.reqres.setHandler "credentials:current", ->
    API.getCredentials()

  App.reqres.setHandler "credentials:username", ->
    credentials = API.getCredentials()
    if !credentials then return false
    credentials.get 'username'

  App.vent.on "credentials:password:update", (newPassword) ->
    API.updatePassword App.request("serverpath:current"), newPassword

  App.vent.on "credentials:password:change", (passwords) ->
    API.changePassword App.request("serverpath:current"), passwords.oldPassword, passwords.newPassword

  App.reqres.setHandler "credentials:upload:params", ->
    API.getParams()

  App.commands.setHandler "credentials:validate", (username, password) ->
    API.validateCredentials App.request("serverpath:current"), username, password

  App.commands.setHandler "credentials:logout", ->
    API.logout()

  App.vent.on "survey:upload:failure:auth", (responseData, errorText, surveyId) ->
    # On native:
    # in the future, could show a temporary login modal to update password
    # if it's an "invalid password" type of error

  App.vent.on "appversion:update", (oldVersion) ->
    API.logout()
