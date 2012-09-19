class PiroPopup.Views.PopupIndex extends Backbone.View
  
  template: SHT['popup/index']
  events:
    'change select.account_switcher'          : 'switchAccount'
    'click .update_data_for_accounts_link'    : 'updateDataTrigger'
    'click .add_story_link'                   : 'addStoryForm'
  
  initialize: (options) ->
    @collection.on 'add', @render
    @collection.on 'reset', @render
    #projects 
    @projects = options.projects
    # global events
    PiroPopup.globalEvents.on "update:pivotal:data", @updatePivotalState
    PiroPopup.globalEvents.on "update:pivotal:progress", @updatePivotalUpdateProgress
  
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
    PiroPopup.db.getProjects PiroPopup.pivotalCurrentAccount.toJSON(), 
      success: (projects) =>
        PiroPopup.pivotalProjects.reset(projects)
        Backbone.history.navigate("", {trigger: true, replace: false})

  updateDataTrigger: (e) =>
    e.preventDefault()
    chrome.runtime.getBackgroundPage (bgPage) ->
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.startDataUpdate()
    
  addStoryForm: (e) =>
    e.preventDefault()
    Backbone.history.navigate("story/new", {trigger: true, replace: false})
    
  updatePivotalState: (info) =>
    return false unless info?
    if info.updateState is true
      @$('#updateDataBox').addClass('loading')
      try
        Piecon.setProgress(0)
      catch e
        # no title
    else
      @$('#updateDataBox').removeClass('loading')
      try
        Piecon.reset()
      catch e
        # no title
  updatePivotalUpdateProgress: (info) =>
    return false unless info?
    progress = parseInt(info.progress)
    progress = 100 if progress > 100
    try
      Piecon.setProgress(progress)
    catch e
      # no title

  onDestroyView: =>
    @collection.off 'add', @render
    @collection.off 'reset', @render
    PiroPopup.globalEvents.off "update:pivotal:data", @updatePivotalState
    PiroPopup.globalEvents.off "update:pivotal:progress", @updatePivotalUpdateProgress
    @childView.destroyView() if @childView?