class PiroPopup.Views.PopupIndex extends Backbone.View
  
  template: SHT['popup/index']
  events:
    'change select.account_switcher'      : 'switchAccount'
  
  initialize: (options) ->
    @collection.on 'add', @render
    @collection.on 'reset', @render
    #projects 
    @projects = options.projects
  
  render: =>
    $(@el).html(@template.render(
      accounts: @collection.toJSON()
    ))
    @renderProjects()
    this
  renderProjects: =>
    @childView.destroyView() if @childView?
    @childView = new PiroPopup.Views.ProjectsIndex(collection: @projects)
    @$('#projectsBox').html(@childView.render().el)
  switchAccount: =>
    currentAccount = @collection.get(parseInt(@$('select.account_switcher').val()))
    return false unless currentAccount?
    PiroPopup.pivotalCurrentAccount = currentAccount
    @resetProjectsList()
  onDestroyView: =>
    @collection.off 'add', @renderOne
    @collection.off 'reset', @renderAll
    @childView.destroyView() if @childView?