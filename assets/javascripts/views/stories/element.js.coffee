class PiroPopup.Views.StoriesElement extends Backbone.View
  tagName: "li"
  className: "story"
  template: SHT['stories/element']
  events:
    "click .story_link_info"          : "showStoryInfo"
  
  initialize: =>
    @model.on 'change', @render
    @model.on 'destroy', @remove

  render: =>
    $(@el).html(@template.render(@model.toJSON()))
    this
    
  showStoryInfo: (e) =>
    e.preventDefault()
    view = new PiroPopup.Views.StoriesShow(model: @model)
    PiroPopup.updateStoryContainer(view)

  remove: =>
    $(@el).remove()
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove