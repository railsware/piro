class PiroPopup.Views.LoginIndex extends Backbone.View
  template: SHT['login/index']
  className: 'space'
  events:
    "click .account_tab_link"             : 'accountTabBox'
    'submit #loginForm'                   : 'submitAccountForm'
    "click .error_box .close-link"        : "closeErrorMessage"
  
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
      @$('div.error_box').empty()
    attributes.error = (jqXHR, textStatus, errorThrown) =>
      @$('div.error_box').html("<div class='error-message'>#{jqXHR.responseText}<a href='#' class='close-link'></a></div>")
    attributes.success = (data, textStatus, jqXHR) =>
      PiroPopup.db.saveAccountAndGetAll data, 
        success: (accounts) =>
          PiroPopup.pivotalAccounts.reset(accounts)
          PiroPopup.pivotalCurrentAccount = PiroPopup.pivotalAccounts.first() if PiroPopup.pivotalAccounts.length > 0
          PiroPopup.initBackground (bgPage) =>
            PiroPopup.bgPage.PiroBackground.startDataUpdate()
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
  
  closeErrorMessage: (e) =>
    e.preventDefault()
    @$('div.error_box').empty()
    
  onDestroyView: =>
    # empty