class PiroPopup.Views.LoginIndex extends Backbone.View
  template: SHT['login/index']
  events:
    'click a.email_box_tab'               : 'openEmailBox'
    'click a.token_box_tab'               : 'openTokenBox'
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
          Backbone.history.navigate("", {trigger: true, replace: false})
    auth = new PivotaltrackerAuthLib(attributes)
  # links
  openEmailBox: (e) =>
    e.preventDefault()
    @$('div.token_box').hide()
    @$('div.email_box').show()
  openTokenBox: (e) =>
    e.preventDefault()
    @$('div.email_box').hide()
    @$('div.token_box').show()
    
  onDestroyView: =>
    # empty