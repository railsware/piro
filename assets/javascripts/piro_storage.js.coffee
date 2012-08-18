root = global ? window

root.PiroStorage =
  accountsKey: "accounts"
  set: (key, data) ->
    root.localStorage.setItem(key, JSON.stringify(data))
    data
  get: (key) ->
    strData = root.localStorage.getItem(key)
    jsonData = if strData? then JSON.parse(strData) else null
    jsonData
  # ACCOUNTS
  getAccounts: ->
    PiroStorage.get(PiroStorage.accountsKey) || []
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
  setAccounts: (accounts) ->
    PiroStorage.set(PiroStorage.accountsKey, accounts)
  sortAccounts: (accountIds) ->
    accounts = _.sortBy PiroStorage.getAccounts(), (account) ->
      _.indexOf accountIds, parseInt(account.id)
    PiroStorage.setAccounts(accounts)
  deleteAccount: (accountId) ->
    accounts = _.reject PiroStorage.getAccounts(), (accountItem) ->
      parseInt(accountItem.id) is parseInt(accountId)
    PiroStorage.setAccounts(accounts)