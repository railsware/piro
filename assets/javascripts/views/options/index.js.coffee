class PiroPopup.Views.OptionsIndex extends Backbone.View
  
  template: SHT['options/index']
  
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

  onDestroyView: =>
    @collection.off 'add', @renderAccount
    @collection.off 'reset', @renderAccounts
    @cleanupChildViews()
  cleanupChildViews: =>
    view.destroyView() for view in @childViews
    @childViews = []