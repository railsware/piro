class PiroPopup.Views.StoriesElement extends Backbone.View
  tagName: "li"
  className: "story_element"
  template: SHT['stories/element']
  events:
    "click .story_link_info"          : "showStoryInfo"
  
  initialize: =>
    @model.on 'change', @render
    @model.on 'destroy', @remove

  render: =>
    $(@el).html(@template.render(@model.toJSON()))
    $(@el).attr("data-story-id", @model.get('id'))
    this
    
  showStoryInfo: (e) =>
    e.preventDefault()
    Backbone.history.navigate("story/#{@model.get("id")}", {trigger: true, replace: true})

  remove: =>
    $(@el).remove()
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove