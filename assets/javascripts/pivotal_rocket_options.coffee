root = global ? window

root.PivotalRocketOptions =
  background_page: chrome.extension.getBackgroundPage()
  # templates
  templates: {}
  
  init: ->
    console.debug PivotalRocketStorage.get_accounts()
    PivotalRocketOptions.init_templates()
    PivotalRocketOptions.init_view()
  # init templates
  init_templates: ->
    PivotalRocketOptions.templates.account = Hogan.compile($('#account_template').html())
  # init option view
  init_view: ->
    # init account list
    $('#accountList').empty()
    if PivotalRocketStorage.get_accounts().length > 0
      for account in PivotalRocketStorage.get_accounts()
        $('#accountList').append(PivotalRocketOptions.templates.account.render(account))
    
$ ->
  PivotalRocketOptions.init()