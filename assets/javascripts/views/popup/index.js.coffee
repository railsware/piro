class PiroPopup.Views.PopupIndex extends Backbone.View
  
  template: SHT['popup/index']
  
  initialize: ->
    @collection.on 'add', @render
    @collection.on 'reset', @render
    # projects
    @projects = new PiroPopup.Collections.Projects
    @projects.reset(PiroStorage.getProjects())
    # projects
    api = new PivotaltrackerApi(PiroStorage.getAccounts()[0])
    api.getProjects
      success: (data, textStatus, jqXHR) =>
        console.log data
  
  render: =>
    $(@el).html(@template.render())
    @renderProjects()
    this
    
  renderProjects: =>
    view = new PiroPopup.Views.ProjectsIndex(collection: @projects)
    @$('#projectsBox').html(view.render().el)