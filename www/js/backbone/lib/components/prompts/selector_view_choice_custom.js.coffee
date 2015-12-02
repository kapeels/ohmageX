@Ohmage.module "Components.Prompts", (Prompts, App, Backbone, Marionette, $, _) ->

  class Prompts.BaseChoiceCustom extends Prompts.BaseComposite
    getTemplate: -> "prompts/choice_custom"
    triggers:
      "click button.my-add": "customchoice:toggle"
      "click .add-form .add-submit": "customchoice:add"
      "click .add-form .add-cancel": "customchoice:cancel"

    initialize: ->
      super

      @listenTo @, 'customchoice:toggle', @toggleChoice
      @listenTo @, 'customchoice:add', @addChoice
      @listenTo @, 'customchoice:cancel', @cancelChoice

      @listenTo @, 'childview:customchoice:remove', @removeChoice

      @listenTo @, 'customchoice:add:invalid', (-> App.execute "dialog:alert", 'invalid custom choice, please try again.')
      @listenTo @, 'customchoice:add:exists', (-> App.execute "dialog:alert", 'Custom choice exists, please try again.')

      @listenTo @, 'response:submit', =>
        @trigger "customchoice:cancel"

    removeChoice: (args) ->
      value = args.model.get 'label'
      @collection.remove @collection.where(label: value)
      @trigger "customchoice:remove", value

    toggleChoice: (args) ->
      $addForm = @$el.find '.add-form'
      $addForm.toggleClass 'hidden'

    cancelChoice: ->
      $addForm = @$el.find '.add-form'
      $addForm.addClass 'hidden'
      $addForm.find(".add-value").val('')

    addChoice: (args) ->
      $addForm = @$el.find '.add-form'
      myVal = $addForm.find(".add-value").val().trim()

      if !!!myVal.length
        # ensure a new custom choice isn't blank.
        @trigger "customchoice:add:invalid"
        return false

      if not $addForm.hasClass 'hidden'

        # add new choice, based on the contents of the text prompt,
        # to the view's Collection. Validation and parsing takes
        # place within the ChoiceCollection's model.

        if args.collection.where(label: myVal).length > 0
          # the custom choice already exists
          @trigger "customchoice:add:exists"
          return false
        myKey = _.guid()

        args.collection.add([{
          "id": myKey
          "key": myKey
          "label": myVal
          "parentId": args.model.get('id')
          "custom": true
        }])

        # clear the input on successful submit.
        @trigger "customchoice:add:success", myVal, myKey
        $addForm.find(".add-value").val('')


  class Prompts.SingleChoiceCustom extends mixOf Prompts.SingleChoice, Prompts.BaseChoiceCustom


  class Prompts.MultiChoiceCustom extends mixOf Prompts.MultiChoice, Prompts.BaseChoiceCustom
