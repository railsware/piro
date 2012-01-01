root = global ? window

root.PivotalRocketBackground =
  account: null
  pivotal_api_lib: null
  
  init_popup: ->
    popup_view = chrome.extension.getViews({type:"popup"})
    if popup_view.length > 0
      for popup in popup_view
        
        if PivotalRocketStorage.get_accounts().length > 0
          popup.$('#loginPage').hide()
      
          PivotalRocketBackground.account = PivotalRocketStorage.get_accounts()[0]
          PivotalRocketBackground.initial_sync()
      
          popup.$('#mainPage').show()
        else
          popup.$('#mainPage').hide()
          popup.$('#loginPage').show()
          
  init_login: ->
    popup_view = chrome.extension.getViews({type:"popup"})
    if popup_view.length > 0
      for popup in popup_view
        
        popup.$('#login_button').click (event) =>
          username = popup.$('#login_username').val()
          password = popup.$('#login_password').val()
          if username? && password?
            pivotal_auth_lib = new PivotalAuthLib
              username: username
              password: password
              success: (data, textStatus, jqXHR) ->
                account = XML2JSON.parse(data, true)
                account = account.person if account.person?
                PivotalRocketBackground.account = PivotalRocketBackground.save_account(account)
                PivotalRocketBackground.initial_sync()
                  
              error: (jqXHR, textStatus, errorThrown) ->
                # errror
  
  initial_sync: ->
    PivotalRocketBackground.pivotal_api_lib = new PivotalApiLib(PivotalRocketBackground.account)
    PivotalRocketBackground.pivotal_api_lib.get_projects
      success: (data, textStatus, jqXHR) =>
        allprojects = XML2JSON.parse(data, true)
        projects = []
        projects = allprojects.projects.project if allprojects.projects? && allprojects.projects.project?
        projects = [projects] if projects.constructor != Array
        PivotalRocketStorage.set_projects(PivotalRocketBackground.account, projects)
        for project in projects
          PivotalRocketBackground.pivotal_api_lib.get_stories_for_project
            project: project
            success: (data, textStatus, jqXHR) =>
              stories = []
              allstories = XML2JSON.parse(data, true)
              stories = allstories.stories.story if allstories.stories? && allstories.stories.story?
              stories = [stories] if stories.constructor != Array
              console.debug stories
            error: (jqXHR, textStatus, errorThrown) ->
              # error
            
      error: (jqXHR, textStatus, errorThrown) ->
        # error
                
  save_account: (account) ->
    if account.email?
      accounts = PivotalRocketStorage.get_accounts()
      is_pushed = false
      new_accounts = for one_account in accounts
        if one_account.email?
          if one_account.email == account.email
            is_pushed = true
            account
          else
            one_account
      if is_pushed is false
        new_accounts.push(account)
      PivotalRocketStorage.set_accounts(new_accounts)
      account