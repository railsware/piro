class PiroPopup.Views.ProjectsIndex extends Backbone.View
  
  template: SHT['projects/index']
  
  initialize: ->
    @collection.on 'add', @renderOne
    @collection.on 'reset', @renderAll
    @childViews = []
  
  render: =>
    $(@el).html(@template.render())
    @renderAll()
    this
    
  renderOne: (project) =>
    view = new PiroPopup.Views.ProjectsElement(model: project)
    @$('.projects_list').append(view.render().el)
    @childViews.push(view)

  renderAll: =>
    @$('.projects_list').empty()
    @cleanupChildViews()
    @collection.each @renderOne
    
  onDestroyView: =>
    @collection.off 'add', @renderOne
    @collection.off 'reset', @renderAll
    @cleanupChildViews()
  cleanupChildViews: =>
    view.destroyView() for view in @childViews
    @childViews = []
