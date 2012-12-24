class PiroPopup.Views.OptionsIndex extends Backbone.View
  
  template: SHT['options/index']
  className: 'space'
  events:
    "click .open_option_box"              : "openOptionBox"
    "submit .options_form"                : "saveFormData"
    "click .custom_format_example_link"   : "showCustomFormatExample"
    "click .account_tab_link"             : "activeTabAction"
    "submit .add_account_form"            : "addAccount"
  
  initialize: (options) ->
    @collection.on 'add', @renderAccount
    @collection.on 'reset', @renderAccounts
    @childViews = []
  
  render: =>
    $(@el).html(@template.render(PiroOptions.db.getAllOptionsLS()))
    @$('select.update_interval_select').val(PiroOptions.db.getUpdateIntervalLS())
    @renderAccounts()
    @_initSortingAccounts()
    this

  showCustomFormatExample: (e) =>
    e.preventDefault()
    @$('input.custom_format_input').val('git commit -am "[#{{id}}] {{name}}"')
    
  openOptionBox: (e) =>
    e.preventDefault()
    element = @$(e.currentTarget)
    if element.data('class') is "account_options_box"
      @$('.options-holder').addClass('accounts')
    else
      @$('.options-holder').removeClass('accounts')
    @$('#optionsTab a').removeClass('active')
    element.addClass('active')
    @$('.option_box').removeClass('opened')
    @$(".#{element.data('class')}").addClass('opened')

  saveFormData: (e) =>
    e.preventDefault()
    @_saveFormData()
    PiroOptions.cleanupPopupViews()
    @$('.save_options_block .save-button').hide()
    @$('.save_options_block .save_status').show()
    setTimeout (=>
      @$('.save_options_block .save-button').show()
      @$('.save_options_block .save_status').hide()
    ), 2000
    
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

  _initSortingAccounts: =>
    @$("ul.accounts_list").sortable
      handle: '.dragable_account'
      axis: 'y'
      placeholder: 'ui-state-highlight'
      update: (event) =>
        objects = @$("ul.accounts_list li")
        objectIds = _.compact($(object).data('account-id') for object in objects)
        PiroOptions.db.setSortedAccountsLS(objectIds)
        PiroOptions.cleanupPopupViews()
    .disableSelection()

  _saveFormData: =>
    PiroOptions.db.setUpdateIntervalLS(parseInt(@$('select.update_interval_select').val()))
    PiroOptions.db.setCustomFormatLS(@$('input.custom_format_input').val())
    PiroOptions.db.setContextMenuLS(@$('input.context_menu_input').is(':checked'))
    chrome.runtime.getBackgroundPage (bgPage) =>
      bgPage.PiroBackground.updateAlarm()
      bgPage.PiroBackground.initContextMenu()

  onDestroyView: =>
    @collection.off 'add', @renderAccount
    @collection.off 'reset', @renderAccounts
    @cleanupChildViews()
  cleanupChildViews: =>
    view.destroyView() for view in @childViews
    @childViews = []