class PiroPopup.Views.LoginIndex extends Backbone.View
  template: SHT['login/index']
  events:
    "click .account_tab_link"             : 'accountTabBox'
    'submit #loginForm'                   : 'submitAccountForm'
  
  initialize: =>
    #empty    
  render: =>
    $(@el).html(@template.render())
    this
  submitAccountForm: (e) =>
    e.preventDefault()
    if @$('div.email_box').is(':visible')
      attributes = 
        username: @$('input.email_input').val()
        password: @$('input.password_input').val()
    else
      attributes = 
        token: @$('input.token_input').val()
    attributes.beforeSend = =>
      @$('div.error_text').hide()
    attributes.error = (jqXHR, textStatus, errorThrown) =>
      @$('div.error_text').text(jqXHR.responseText).show()
    attributes.success = (data, textStatus, jqXHR) =>
      PiroPopup.db.saveAccountAndGetAll data, 
        success: (accounts) =>
          PiroPopup.pivotalAccounts.reset(accounts)
          PiroPopup.pivotalCurrentAccount = PiroPopup.pivotalAccounts.first() if PiroPopup.pivotalAccounts.length > 0
          Backbone.history.navigate("", {trigger: true, replace: true})
    auth = new PivotaltrackerAuthLib(attributes)
  # links
  accountTabBox: (e) =>
    e.preventDefault()
    object = $(e.currentTarget)
    @$('.account_tab_link').removeClass('active')
    object.addClass('active')
    @$('.account_tab_box').removeClass('active')
    @$(".#{object.data('div-class')}").addClass('active')
    
  onDestroyView: =>
    # empty