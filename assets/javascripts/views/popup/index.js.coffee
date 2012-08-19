class PiroPopup.Views.PopupIndex extends Backbone.View
  
  template: SHT['popup/index']
  
  initialize: ->
    @collection.on 'add', @render
    @collection.on 'reset', @render
    # projects
    @currentAccount = @collection.first()
    @projects = new PiroPopup.Collections.Projects
    @projects.reset(PiroStorage.getProjects(@currentAccount.toJSON()))
  
  render: =>
    $(@el).html(@template.render(
      accounts: @collection.toJSON()
    ))
    @renderProjects()
    this
    
  renderProjects: =>
    view = new PiroPopup.Views.ProjectsIndex(collection: @projects)
    @$('#projectsBox').html(view.render().el)