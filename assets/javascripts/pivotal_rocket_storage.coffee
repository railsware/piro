root = global ? window

root.PivotalRocketStorage = 
  accounts: null
  
  set: (key, json) ->
    window.localStorage.setItem(key, JSON.stringify(json))
    json
  get: (key) ->
    str_data = window.localStorage.getItem(key)
    json_data = if str_data? then JSON.parse(str_data) else null
    json_data
    
  get_accounts: ->
    if !PivotalRocketStorage.accounts?
      PivotalRocketStorage.accounts = PivotalRocketStorage.get("accounts")
      PivotalRocketStorage.accounts ||= []
    PivotalRocketStorage.accounts
    
  set_accounts: (accounts) ->
    PivotalRocketStorage.set("accounts", accounts)
    PivotalRocketStorage.accounts = accounts
    
  set_projects: (account, projects) ->
    PivotalRocketStorage.set("projects_" + account.id, projects)
    
  get_projects: (account) ->
    PivotalRocketStorage.get("projects_" + account.id)