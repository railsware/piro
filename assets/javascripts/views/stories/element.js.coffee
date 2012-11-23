class PiroPopup.Views.StoriesElement extends Backbone.View
  tagName: "li"
  className: "story_element"
  template: SHT['stories/element']
  events:
    "click .story_link_info"          : "showStoryInfo"
    "click .story_label"              : "filterByLabel"
    "click .story_owned_by"           : "filterByOwner"
  
  initialize: =>
    @model.on 'change', @render
    @model.on 'change:project_id', @remove
    @model.on 'destroy', @remove

  render: =>
    $(@el).html(@template.render(@model.toJSON()))
    $(@el).attr("data-story-id", @model.get('id'))
    this
    
  showStoryInfo: (e) =>
    e.preventDefault()
    Backbone.history.navigate("story/#{@model.get("id")}", {trigger: true, replace: true})

  filterByLabel: (e) =>
    e.preventDefault()
    PiroPopup.globalEvents.trigger "filter:stories", "##{$(e.currentTarget).text()}"

  filterByOwner: (e) =>
    e.preventDefault()
    PiroPopup.globalEvents.trigger "filter:stories", "@#{$(e.currentTarget).text()}"

  remove: =>
    $(@el).remove()
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove