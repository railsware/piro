root = global ? window

class root.PiroStorage
  constructor: (params = {}) ->
    @dbName = "piro"
    @dbVersion = "1"
    @db = null
    @indexedDB = root.indexedDB || root.webkitIndexedDB || root.mozIndexedDB
    if "webkitIndexedDB" of root
      window.IDBTransaction = root.webkitIDBTransaction
      window.IDBKeyRange = root.webkitIDBKeyRange
    request = @indexedDB.open(@dbName)
    request.onerror = @dbError
    request.onsuccess = (e) =>
      @db = e.target.result
      unless @dbVersion is @db.version
        setVrequest = @db.setVersion(@dbVersion)
        setVrequest.onerror = @dbError
        setVrequest.onsuccess = (e) =>
          @db.deleteObjectStore @accountsKey() if @db.objectStoreNames.contains(@accountsKey())
          accounts = @db.createObjectStore(@accountsKey(),
            keyPath: "id"
          )
          @db.deleteObjectStore @projectsKey() if @db.objectStoreNames.contains(@projectsKey())
          projects = @db.createObjectStore(@projectsKey(),
            keyPath: "account_id"
          )
          @db.deleteObjectStore @storiesKey() if @db.objectStoreNames.contains(@storiesKey())
          stories = @db.createObjectStore(@storiesKey(),
            keyPath: "id"
          )
          stories.createIndex("project_id", "project_id", { unique: false })
          e.target.transaction.oncomplete = ->
            params.success.call(null) if params.success?
      else
        params.success.call(null) if params.success?
  # KEYS
  accountsKey: =>
    "accounts"
  projectsKey: =>
    "projects"
  storiesKey: =>
    "stories"
  # ACCOUNTS
  getAccounts: (params = {}) =>
    accounts = []
    trans = @db.transaction([@accountsKey()], "readwrite")
    store = trans.objectStore(@accountsKey())
    keyRange = IDBKeyRange.lowerBound(0)
    cursorRequest = store.openCursor(keyRange)
    cursorRequest.onerror = @dbError
    cursorRequest.onsuccess = (e) =>
      cursor = e.target.result
      if cursor?
        accounts.push(cursor.value)
        cursor.continue()
      else
        params.success.call(null, accounts) if params.success?
  saveAccount: (account, params = {}) =>
    trans = @db.transaction([@accountsKey()], "readwrite")
    store = trans.objectStore(@accountsKey())
    request = store.put account
    request.onerror = @dbError
    request.onsuccess = (e) =>
      params.success.call(null) if params.success?
  saveAccountAndGetAll: (account, params = {}) =>
    @saveAccount account, 
      success: =>
        @getAccounts
          success: (accounts) =>
            params.success.call(null, accounts) if params.success?
  # PROJECTS
  getProjects: (account, params = {}) =>
    projects = []
    trans = @db.transaction([@projectsKey()], "readwrite")
    store = trans.objectStore(@projectsKey())
    request = store.get(account.id)
    request.onerror = @dbError
    request.onsuccess = (e) =>
      data = e.target.result
      params.success.call(null, data.projects) if params.success?
  setProjects: (account, projects, params = {}) =>
    trans = @db.transaction([@projectsKey()], "readwrite")
    store = trans.objectStore(@projectsKey())
    data = 
      account_id: account.id
      projects: projects
    request = store.put data
    request.onerror = @dbError
    request.onsuccess = (e) =>
      params.success.call(null) if params.success?
  getFullProjects: (account, params = {}) =>
    @getProjects account, 
      success: (projects) =>
        allProjects = projects
        projectsCount = allProjects.length
        for project in allProjects
          @getStoriesByProject project, 
            success: (project, stories) =>
              projectsCount--
              _.extend(allProjects[_.indexOf(allProjects, project)], {stories: stories})
              if projectsCount <= 0
                params.success.call(null, allProjects) if params.success?
  # STORIES
  setStories: (stories, params = {}) =>
    trans = @db.transaction([@storiesKey()], "readwrite")
    store = trans.objectStore(@storiesKey())
    for story in stories
      request = store.put story
      request.onerror = @dbError
  getStoriesByProject: (project, params = {}) =>
    stories = []
    trans = @db.transaction([@storiesKey()], "readwrite")
    store = trans.objectStore(@storiesKey())
    index = store.index("project_id")
    projectIdVal = IDBKeyRange.only(project.id.toString())
    cursorRequest = index.openCursor(projectIdVal)
    cursorRequest.onerror = @dbError
    cursorRequest.onsuccess = (e) =>
      cursor = e.target.result
      if cursor?
        stories.push(cursor.value)
        cursor.continue()
      else
        params.success.call(null, project, stories) if params.success?
  # UTILS
  dbError: (e) =>
    console.error "IndexedDB error"
    console.error e
###        
  # DB
  
  # KEYS
  accountsKey: "accounts"
  projectsKey: "projects"
  storiesKey: "stories"
  # STORAGE
  set: (key, data) ->
    try
      root.localStorage.setItem(key, JSON.stringify(data))
    catch e
      if e.name is "QUOTA_EXCEEDED_ERR"
        #root.localStorage.clear()
        console.error "QUOTA_EXCEEDED_ERR catch BEGIN"
        console.error "Key: #{key}"
        console.error "Data: #{data}"
        console.error "QUOTA_EXCEEDED_ERR catch END"
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
###