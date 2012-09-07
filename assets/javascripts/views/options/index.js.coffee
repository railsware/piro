class PiroPopup.Views.OptionsIndex extends Backbone.View
  
  template: SHT['options/index']
  events:
    "click .open_account_link"            : "openAccounBox"
    "click .close_account_link"           : "closeAccounBox"
    "click .account_tab_link"             : "activeTabAction"
  
  initialize: (options) ->
    @collection.on 'add', @renderAccount
    @collection.on 'reset', @renderAccounts
    @childViews = []
  
  render: =>
    $(@el).html(@template.render())
    @renderAccounts()
    this
    
  renderAccount: (account) =>
    view = new PiroPopup.Views.OptionsAccount(model: account)
    @$('.accounts_list').append(view.render().el)
    @childViews.push(view)
    
  renderAccounts: =>
    @$('.accounts_list').empty()
    @cleanupChildViews()
    @collection.each @renderAccount
    
  openAccounBox: (e) =>
    e.preventDefault()
    @$('.account_box').addClass('show')
  closeAccounBox: (e) =>
    e.preventDefault()
    @$('.account_box').removeClass('show')
  activeTabAction: (e) =>
    e.preventDefault()
    object = $(e.currentTarget)
    @$('.account_tab_link').removeClass('active')
    object.addClass('active')
    @$('.account_tab_box').removeClass('active')
    @$(".#{object.data('div-class')}").addClass('active')

  onDestroyView: =>
    @collection.off 'add', @renderAccount
    @collection.off 'reset', @renderAccounts
    @cleanupChildViews()
  cleanupChildViews: =>
    view.destroyView() for view in @childViews
    @childViews = []