class PiroPopup.Views.ProjectsElement extends Backbone.View
  tagName: "li"
  className: "project"
  template: SHT['projects/element']
  events:
    "click .story_element"          : "openStories"
    "click .project_settings"       : "openSettings"
  
  initialize: =>
    @model.on 'change', @render
    @model.on 'destroy', @remove

  render: =>
    $(@el).html(@template.render(@model.toJSON()))
    this

  remove: =>
    $(@el).remove()
    
  openStories: (e) =>
    e.preventDefault()
    PiroPopup.db.getStoriesByProject @model.toJSON(), 
      success: (project, data) =>
        stories = new PiroPopup.Collections.Stories
        stories.reset(data)
        projectView = new PiroPopup.Views.StoriesIndex(collection: stories)
        PiroPopup.updateStoriesContainer(projectView)
        
  openSettings: (e) =>
    e.preventDefault()
    @popupView = new PiroPopup.Views.ProjectsSettings(model: @model)
    $("#popupContainer").empty().html(@popupView.render().el)
    $("#popupContainer").dialog
      modal: true
      resizable: false
      draggable: false
      close: (event, ui) =>
        @popupView.onDestroyView() if @popupView? && @popupView.onDestroyView?
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove
