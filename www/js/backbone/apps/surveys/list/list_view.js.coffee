@Ohmage.module "SurveysApp.List", (List, App, Backbone, Marionette, $, _) ->

  class List.Survey extends App.Views.ItemView
    initialize: ->
      @listenTo @model, 'change', @render
    tagName: 'li'
    getTemplate: ->
      if @model.get('status') is 'running' then "surveys/list/_item_running" else "surveys/list/_item_stopped"
    triggers:
      "click .stopped.survey [role=\"link\"]": "stopped:clicked"
      "click .stopped.survey button.navigate": "stopped:clicked"
      "click .running.survey [role=\"link\"]": "running:clicked"
      "click .running.survey button.navigate": "running:clicked"
      "click .running.survey .clock button": "running:clicked"
    serializeData: ->
      data = @model.toJSON()
      data.showTime = App.request("surveys:local:triggered:exists", @model.get('id'))
      data

  class List.SelectorItem extends App.Views.ItemView
    tagName: "option"
    template: "surveys/list/_selector_item"
    attributes: ->
      options = {}
      options['value'] = @model.get 'id'
      if @model.isChosen() then options['selected'] = 'selected'
      options

  class List.CampaignsSelector extends App.Views.CollectionView
    initialize: ->
      @listenTo @, "campaign:selected", (-> @collection.chooseById @$el.val())
    tagName: "select"
    childView: List.SelectorItem
    triggers: ->
      "change": "campaign:selected"

  class List.CampaignInfoButton extends App.Views.ItemView
    initialize: ->
      @model = @collection.findWhere(chosen: true)
      @listenTo @collection, 'change:chosen', @chosenRender
    chosenRender: (model) ->
      if model.isChosen()
        @model = model
        @render
    tagName: "div"
    template: "surveys/list/info_button"
    attributes: ->
      if @collection.findWhere(chosen: true).get('name') is 'All'
        return {
          class: "hide"
        }
    triggers:
      "click": "info:clicked"
    serializeData: ->
      data = @model.toJSON()
      data

  class List.SurveysEmpty extends App.Views.ItemView
    className: "empty-container"
    template: "surveys/list/_surveys_empty"

  class List.Surveys extends App.Views.CompositeView
    tagName: 'nav'
    className: 'list'
    template: "surveys/list/surveys"
    childView: List.Survey
    childViewContainer: "ul"
    emptyView: List.SurveysEmpty

  class List.Layout extends App.Views.Layout
    id: 'surveys'
    template: "surveys/list/list_layout"
    regions:
      infoRegion: "#info-region"
      infobuttonRegion: "#infobutton-region"
      selectorRegion: "#selector-region"
      listRegion: "#list-region"
    triggers:
      "click .campaigns-link": "link:campaigns:clicked"
    serializeData: ->
      data = @collection.findWhere(chosen: true).toJSON()
      data.internalLinksEnabled = App.custom.functionality.internal_links_enabled
      data.campaignsWord = App.dictionary('pages','campaign').capitalizeFirstLetter()
      data
