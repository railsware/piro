class PiroPopup.Views.ProjectsElement extends Backbone.View
  tagName: "li"
  className: "project"
  template: SHT['projects/element']
  events:
    "click .story_element"          : "openStories"
  
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
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove
