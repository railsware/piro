class PiroPopup.Views.PopupIndex extends Backbone.View
  
  template: SHT['popup/index']
  events:
    'change select.account_switcher'      : 'switchAccount'
  
  initialize: ->
    @collection.on 'add', @render
    @collection.on 'reset', @render
    #projects 
    @projects = new PiroPopup.Collections.Projects
    @projects.on 'reset', @renderProjects
    @resetProjectsList()
  
  render: =>
    $(@el).html(@template.render(
      accounts: @collection.toJSON()
    ))
    @renderProjects()
    this
  renderProjects: =>
    @childView = new PiroPopup.Views.ProjectsIndex(collection: @projects)
    @$('#projectsBox').html(@childView.render().el)
  switchAccount: =>
    currentAccount = @collection.get(parseInt(@$('select.account_switcher').val()))
    return false unless currentAccount?
    PiroPopup.pivotalCurrentAccount = currentAccount
    @resetProjectsList()
  resetProjectsList: =>
    PiroPopup.db.getFullProjects PiroPopup.pivotalCurrentAccount.toJSON(), 
      success: (projects) =>
        @projects.reset(projects)
        
  onDestroyView: =>
    @collection.off 'add', @renderOne
    @collection.off 'reset', @renderAll
    @projects.off 'reset', @renderProjects
    @childView.destroyView() if @childView?