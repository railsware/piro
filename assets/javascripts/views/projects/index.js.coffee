class PiroPopup.Views.ProjectsIndex extends Backbone.View
  
  template: SHT['projects/index']
  
  initialize: ->
    @collection.on 'add', @renderOne
    @collection.on 'reset', @renderAll
  
  render: =>
    $(@el).html(@template.render())
    @renderAll()
    this
    
  renderOne: (project) =>
    view = new PiroPopup.Views.ProjectsElement(model: project)
    @$('.projects_list').append(view.render().el)

  renderAll: =>
    @$('.projects_list').empty()
    projects = @collection.filter((project) =>
      project.stories.length > 0
    )
    @renderOne(project) for project in projects
