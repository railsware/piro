class PiroPopup.Views.ProjectsIndex extends Backbone.View
  
  template: SHT['projects/index']
  
  initialize: ->
    @collection.on 'add', @renderOne
    @collection.on 'reset', @renderAll
    PiroPopup.globalEvents.on "update:data:finished", @getProjectsAndRender
    @childViews = []
  
  render: =>
    $(@el).html(@template.render())
    @renderAll()
    @sortBinding()
    this

  getProjectsAndRender: =>
    PiroPopup.db.getProjects PiroPopup.pivotalCurrentAccount.toJSON(),
      success: (projects) =>
        PiroPopup.pivotalProjects.reset(projects)

  renderOne: (project) =>
    view = new PiroPopup.Views.ProjectsElement(model: project)
    @$('.projects_list').append(view.render().el)
    @childViews.push(view)

  renderAll: =>
    @$('.projects_list').empty()
    @cleanupChildViews()
    @collection.each @renderOne
    
  sortBinding: =>
    @$(".projects_list").sortable
      handle: 'span.sort_project'
      axis: 'y'
      placeholder: 'ui-state-highlight'
      update: (e) =>
        objects = @$("li.project_element")
        objectIds = []
        objectIds.push($(object).data('project-id')) for object in objects
        PiroPopup.db.setSortedProjectsLS(PiroPopup.pivotalCurrentAccount.toJSON(), objectIds) if objectIds.length > 0
    .disableSelection()
    
  onDestroyView: =>
    @collection.off 'add', @renderOne
    @collection.off 'reset', @renderAll
    PiroPopup.globalEvents.off "update:data:finished", @getProjectsAndRender
    @cleanupChildViews()
  cleanupChildViews: =>
    view.destroyView() for view in @childViews
    @childViews = []
