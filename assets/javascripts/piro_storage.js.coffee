root = global ? window

root.PiroStorage =
  # KEYS
  accountsKey: "accounts"
  projectsKey: "projects"
  # STORAGE
  set: (key, data) ->
    try
      root.localStorage.setItem(key, JSON.stringify(data))
    catch e
      if e.name is "QUOTA_EXCEEDED_ERR"
        root.localStorage.clear()
      else
        # localStorage not available
    data
  get: (key) ->
    strData = root.localStorage.getItem(key)
    jsonData = if strData? then JSON.parse(strData) else null
    jsonData
  # ACCOUNTS
  getAccounts: ->
    PiroStorage.get(PiroStorage.accountsKey) || []
  setAccounts: (accounts) ->
    PiroStorage.set(PiroStorage.accountsKey, accounts)
  findAccount: (accountId) ->
    account = _.find PiroStorage.getAccounts(), (accountItem) ->
      parseInt(accountItem.id) is parseInt(accountId)
    account
  saveAccount: (account) ->
    oldAccount = PiroStorage.findAccount(account.id)
    unless oldAccount?
      accounts = PiroStorage.getAccounts()
      accounts.push(account)
    else
      accounts = for accountItem in PiroStorage.getAccounts()
        if parseInt(accountItem.id) is parseInt(account.id) then account else accountItem
    PiroStorage.setAccounts(accounts)
    account
  sortAccounts: (accountIds) ->
    accounts = _.sortBy PiroStorage.getAccounts(), (account) ->
      _.indexOf accountIds, parseInt(account.id)
    PiroStorage.setAccounts(accounts)
  deleteAccount: (accountId) ->
    accounts = _.reject PiroStorage.getAccounts(), (accountItem) ->
      parseInt(accountItem.id) is parseInt(accountId)
    PiroStorage.setAccounts(accounts)
  # PROJECTS
  getProjects: (account) ->
    PiroStorage.get("#{PiroStorage.projectsKey}_#{account.id}") || []
  setProjects: (account, projects) ->
    PiroStorage.set("#{PiroStorage.projectsKey}_#{account.id}", projects)
  findProject: (account, projectId) ->
    project = _.find PiroStorage.getProjects(account), (projectItem) ->
      parseInt(projectItem.id) is parseInt(projectId)
    project