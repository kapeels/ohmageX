@Ohmage.module "Entities", ((Entities, App, Backbone, Marionette, $, _, markdown) ->

  # This entity handles markdown parsing.
  # Note that this module includes an extra parameter "markdown"
  # that is passed in from the global scope.

  API =
    getMarkdown: (options) ->
      # TODO: offline image capability feature
      # When online, intercept image references and cache them
      # for inline replacement

      # For caching, use other options passed in to this method to
      # extract and reference the correct image ID and/or
      # create the appropriate image file

      # TODO: Add HTML escape before parsing into markdown
      markdown.toHTML options.originalText

    getMarkdownChoices: (options) ->
      # TODO: offline image capability feature
      # When online, intercept image references and cache them
      # for inline replacement

      # For caching, use other options passed in to this method to
      # extract and reference the correct image ID and/or
      # create the appropriate image file
      newChoices = new Entities.ChoiceCollection options.collection.toJSON()

      newChoices.each (item) ->
        label = item.get 'label'
        item.set 'label', markdown.toHTML(label)

      newChoices

  App.reqres.setHandler "prompt:markdown", (options) ->
    API.getMarkdown options

  App.reqres.setHandler "prompt:markdown:choices", (options) ->
    if not (options.collection instanceof Entities.ChoiceCollection) then throw new Error "prompt:markdown:choice `collection` option is not a ChoiceCollection"
    API.getMarkdownChoices options

), markdown
