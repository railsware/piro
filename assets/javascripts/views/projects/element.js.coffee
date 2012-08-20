class PiroPopup.Views.ProjectsElement extends Backbone.View
  tagName: "li"
  className: "project"
  template: SHT['projects/element']
  events:
    "click .story_element"          : "openStory"
  
  initialize: =>
    @model.on 'change', @render
    @model.on 'destroy', @remove

  render: =>
    $(@el).html(@template.render(@model.toJSON()))
    this

  remove: =>
    $(@el).remove()
    
  openStory: (e) =>
    e.preventDefault()
    Backbone.history.loadUrl("project/#{@model.get('id')}")
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove
