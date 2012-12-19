class PiroPopup.Views.OptionsIndex extends Backbone.View
  
  template: SHT['options/index']
  className: 'space'
  events:
    "click .open_option_box"              : "openOptionBox"
    "submit .options_form"                 : "saveFormData"
    "click .account_tab_link"             : "activeTabAction"
    "submit .add_account_form"            : "addAccount"
  
  initialize: (options) ->
    @collection.on 'add', @renderAccount
    @collection.on 'reset', @renderAccounts
    @childViews = []
  
  render: =>
    $(@el).html(@template.render())
    @renderAccounts()
    this
    
  openOptionBox: (e) =>
    e.preventDefault()
    @$('.options-holder').toggleClass('accounts')
    element = @$(e.currentTarget)
    @$('#optionsTab a').removeClass('active')
    element.addClass('active')
    @$('.option_box').removeClass('opened')
    @$(".#{element.data('class')}").addClass('opened')

  saveFormData: (e) =>
    e.preventDefault()
    # save data
    PiroOptions.cleanupPopupViews()
    @$('.flash_msg').slideDown(400, =>
      setTimeout (=> @$('.flash_msg').slideUp(400)), 3000
    )    
    
  renderAccount: (account) =>
    view = new PiroPopup.Views.OptionsAccount(model: account)
    @$('.accounts_list').append(view.render().el)
    @childViews.push(view)
    
  renderAccounts: =>
    @$('.accounts_list').empty()
    @cleanupChildViews()
    @collection.each @renderAccount
    
  activeTabAction: (e) =>
    e.preventDefault()
    object = $(e.currentTarget)
    @$('.account_tab_link').removeClass('active')
    object.addClass('active')
    @$('.account_tab_box').removeClass('active')
    @$(".#{object.data('div-class')}").addClass('active')
  
  addAccount: (e) =>
    e.preventDefault()
    if @$('div.account_email_box').is(':visible')
      attributes = 
        username: @$('input.account_email').val()
        password: @$('input.account_password').val()
    else
      attributes = 
        token: @$('input.account_token').val()
    attributes.beforeSend = =>
      @$('div.error_text').hide()
    attributes.error = (jqXHR, textStatus, errorThrown) =>
      @$('div.error_text').text(jqXHR.responseText).show()
    attributes.success = (data, textStatus, jqXHR) =>
      if @$('input.account_company').val().length > 0
        account = _.extend(data, {company: @$('input.account_company').val()})
      else
        account = data
      PiroOptions.db.saveAccountAndGetAll account, 
        success: (accounts) =>
          @$('.add_account_form')[0].reset()
          @collection.reset(accounts)
          @closeAccounBox()
          PiroOptions.cleanupPopupViews()
    auth = new PivotaltrackerAuthLib(attributes)

  onDestroyView: =>
    @collection.off 'add', @renderAccount
    @collection.off 'reset', @renderAccounts
    @cleanupChildViews()
  cleanupChildViews: =>
    view.destroyView() for view in @childViews
    @childViews = []