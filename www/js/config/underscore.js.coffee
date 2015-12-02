do (_, jstz) ->
  # Add custom underscore methods

  _.mixin guid: ->
    "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace /[xy]/g, (c) ->
      r = Math.random() * 16 | 0
      v = (if c is "x" then r else (r & 0x3 | 0x8))
      v.toString 16

  _.mixin jstz: ->
    tz = jstz.determine()
    tz.name()
