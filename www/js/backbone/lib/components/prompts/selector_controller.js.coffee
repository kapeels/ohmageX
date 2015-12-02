@Ohmage.module "Components.Prompts", (Prompts, App, Backbone, Marionette, $, _) ->

  # This Prompt Selector returns a specific view, based on the
  # promptType and loads it with the passed in Entity.

  class Prompts.SelectorController extends App.Controllers.Application
    initialize: (options) ->
      { surveyId, stepId, type, entity } = options

      @surveyId = surveyId
      @stepId = stepId

      promptMarkdown = App.request "prompt:markdown",
        originalText: entity.get 'promptText'
        campaign_urn: App.request "survey:saved:urn", @surveyId
        surveyId: @surveyId
        stepId: @stepId

      entity.set 'promptTextMarkdown', promptMarkdown

      if type in ["single_choice", "single_choice_custom", "multi_choice", "multi_choice_custom"]

        promptChoicesMarkdown = App.request "prompt:markdown:choices",
          collection: entity.get 'properties'
          campaign_urn: App.request "survey:saved:urn", @surveyId
          surveyId: @surveyId
          stepId: @stepId

        entity.set 'promptChoices', promptChoicesMarkdown

      @myView = @selectView entity, type

      @listenTo @myView, "customchoice:add:success", (myVal, myKey) =>
        console.log "customchoice:add:success handler", myVal, myKey
        App.execute "prompt:customchoice:add", @surveyId, @stepId, myVal, myKey

      @listenTo @myView, "customchoice:remove", (myVal) =>
        console.log "customchoice:remove handler", myVal
        App.execute "prompt:customchoice:remove", @surveyId, @stepId, myVal

      @listenTo @myView, "response:submit", (response, surveyId, stepId) ->
        console.log "response:submit"
        App.execute "response:validate", response, surveyId, stepId

      # Ensure this controller is removed during view cleanup.
      @listenTo @myView, "destroy", @destroy

    selectView: (entity, type) ->
      switch (type)
        when "text"
          return new Prompts.Text
            model: entity
        when "number"
          return new Prompts.Number
            model: entity
        when "timestamp"
          return new Prompts.Timestamp
            model: entity
        when "photo"
          ###
          Note: If images ever need to be stored anywhere but in the Responses
          object before submitting, this may need to be refactored to merge images
          from a separate data store. The following is recommended:

          Entity used in `survey_upload_images` is used immediately when an
          image is saved, and not just before survey upload. This requires a
          `survey:images:get` method that fetches a base64 images by UUID.
          Why? Because the Response object, instead of containing the raw
          base64, would contain the UUID, as it does immediately before
          survey upload.

          Before a Photo prompt is rendered, it must fetch a new Prompt Photo
          entity instead of the basic entity that most other Prompts get
          (currently the other exception being Custom Choice prompts). This
          entity gets the response UUID and fetches the base64 so it can be
          inserted into the prompt's `<canvas>` thumbnail.
          ###
          return new Prompts.Photo
            model: entity
        when "single_choice"
          return new Prompts.SingleChoice
            model: entity
            collection: entity.get 'promptChoices'
        when "single_choice_custom"
          return new Prompts.SingleChoiceCustom
            model: entity
            collection: App.request "prompt:customchoices:merged", @surveyId, @stepId, entity.get 'promptChoices'
        when "multi_choice"
          return new Prompts.MultiChoice
            model: entity
            collection: entity.get 'promptChoices'
        when "multi_choice_custom"
          return new Prompts.MultiChoiceCustom
            model: entity
            collection: App.request "prompt:customchoices:merged", @surveyId, @stepId, entity.get 'promptChoices'
        when "document"
          return new Prompts.Document
            model: entity
        when "video"
          return new Prompts.Video
            model: entity
        else
          return new Prompts.Unsupported
            model: App.request('prompt:unsupported:entity', type, entity.get('id'))

  App.reqres.setHandler "prompts:view", (surveyId, stepId, entity, type) ->
    selector = new Prompts.SelectorController
      surveyId: surveyId
      stepId: stepId
      entity: entity
      type: type

    selector.myView
