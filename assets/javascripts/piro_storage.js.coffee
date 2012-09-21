root = global ? window

class root.PiroStorage
  constructor: (params = {}) ->
    @dbName = "piro"
    @dbVersion = "1"
    @db = null
    @indexedDB = root.indexedDB || root.webkitIndexedDB || root.mozIndexedDB
    if "webkitIndexedDB" of root
      root.IDBTransaction = root.webkitIDBTransaction
      root.IDBKeyRange = root.webkitIDBKeyRange
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
          @db.deleteObjectStore @projectsIconsKey() if @db.objectStoreNames.contains(@projectsIconsKey())
          project_icons = @db.createObjectStore(@projectsIconsKey(),
            keyPath: "id"
          )
          @db.deleteObjectStore @storiesKey() if @db.objectStoreNames.contains(@storiesKey())
          stories = @db.createObjectStore(@storiesKey(),
            keyPath: "id"
          )
          stories.createIndex("project_id", "project_id", { unique: false })
          # clear local storage
          @clearLocalStorage()
          # done
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
  projectsIconsKey: =>
    "project_icons"
  # ACCOUNTS
  getAccounts: (params = {}) =>
    accounts = []
    trans = @db.transaction([@accountsKey()], "readonly")
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
  deleteAccount: (accountId, params = {}) =>
    trans = @db.transaction([@accountsKey()], "readwrite")
    store = trans.objectStore(@accountsKey())
    request = store.delete(accountId)
    request.onerror = @dbError
    request.onsuccess = (e) =>
      data = e.target.result
      params.success.call(null, data) if params.success?
  # PROJECTS
  getAllProjects: (params = {}) =>
    projects = []
    trans = @db.transaction([@projectsKey()], "readonly")
    store = trans.objectStore(@projectsKey())
    keyRange = IDBKeyRange.lowerBound(0)
    cursorRequest = store.openCursor(keyRange)
    cursorRequest.onerror = @dbError
    cursorRequest.onsuccess = (e) =>
      cursor = e.target.result
      if cursor?
        projects.push(cursor.value)
        cursor.continue()
      else
        if params.success?
          projects = (project.projects for project in projects)
          params.success.call(null, _.uniq(_.flatten(projects)))
  getProjects: (account, params = {}) =>
    projects = []
    trans = @db.transaction([@projectsKey()], "readonly")
    store = trans.objectStore(@projectsKey())
    request = store.get(account.id)
    request.onerror = @dbError
    request.onsuccess = (e) =>
      data = e.target.result
      @getProjectIcons
        success: (icons) =>
          projects = if data? && data.projects? then data.projects else []
          if projects.length is 0
            params.success.call(null, projects) if params.success?
            return false
          # icons for projects
          for icon in icons
            project = _.find(projects, (project) ->
              project.id is icon.id
            )
            _.extend(projects[_.indexOf(projects, project)], {icon: icon.icon})
          # sort projects
          sortedProjectIds = @getSortedProjectsLS(account)
          projects = _.sortBy(projects, (project) ->
            index = _.indexOf(sortedProjectIds, parseInt(project.id))
            if index is -1 then 999 else index
          ) if sortedProjectIds? && sortedProjectIds.length > 0
          params.success.call(null, projects) if params.success?
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
  getStoryById: (storyId, params = {}) =>
    trans = @db.transaction([@storiesKey()], "readonly")
    store = trans.objectStore(@storiesKey())
    request = store.get(storyId)
    request.onerror = @dbError
    request.onsuccess = (e) =>
      data = e.target.result
      params.success.call(null, data) if params.success?
  getStoriesByProject: (project, params = {}) =>
    stories = []
    trans = @db.transaction([@storiesKey()], "readonly")
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
  getStories: (params = {}) =>
    stories = []
    trans = @db.transaction([@storiesKey()], "readonly")
    store = trans.objectStore(@storiesKey())
    keyRange = IDBKeyRange.lowerBound(0)
    cursorRequest = store.openCursor(keyRange)
    cursorRequest.onerror = @dbError
    cursorRequest.onsuccess = (e) =>
      cursor = e.target.result
      if cursor?
        stories.push(cursor.value)
        cursor.continue()
      else
        params.success.call(null, stories) if params.success?
  deleteStoryById: (storyId, params = {}) =>
    trans = @db.transaction([@storiesKey()], "readwrite")
    store = trans.objectStore(@storiesKey())
    request = store.delete(storyId)
    request.onerror = @dbError
    request.onsuccess = (e) =>
      data = e.target.result
      params.success.call(null, data) if params.success?
  # PROJECT ICONS
  getProjectIcons: (params = {}) =>
    icons = []
    trans = @db.transaction([@projectsIconsKey()], "readonly")
    store = trans.objectStore(@projectsIconsKey())
    keyRange = IDBKeyRange.lowerBound(0)
    cursorRequest = store.openCursor(keyRange)
    cursorRequest.onerror = @dbError
    cursorRequest.onsuccess = (e) =>
      cursor = e.target.result
      if cursor?
        icons.push(cursor.value)
        cursor.continue()
      else
        params.success.call(null, icons) if params.success?
  getProjectIcon: (project, params = {}) =>
    icon = null
    trans = @db.transaction([@projectsIconsKey()], "readonly")
    store = trans.objectStore(@projectsIconsKey())
    keyRange = IDBKeyRange.only(project.id.toString())
    cursorRequest = store.openCursor(keyRange)
    cursorRequest.onerror = @dbError
    cursorRequest.onsuccess = (e) =>
      cursor = e.target.result
      params.success.call(null, cursor.value) if params.success?
  saveProjectIcon: (project, icon, params = {}) =>
    trans = @db.transaction([@projectsIconsKey()], "readwrite")
    store = trans.objectStore(@projectsIconsKey())
    request = store.put 
      id: project.id
      icon: icon
    request.onerror = @dbError
    request.onsuccess = (e) =>
      params.success.call(null) if params.success?
  deleteProjectIcon: (projectId, params = {}) =>
    trans = @db.transaction([@projectsIconsKey()], "readwrite")
    store = trans.objectStore(@projectsIconsKey())
    request = store.delete(projectId)
    request.onerror = @dbError
    request.onsuccess = (e) =>
      data = e.target.result
      params.success.call(null, data) if params.success?
  # UTILS
  dbError: (e) =>
    console.error "IndexedDB error"
    console.error e
  # localStorage
  setLocalStorage: (key, data) =>
    try
      root.localStorage.setItem(key, JSON.stringify(data))
    catch e
      if e.name is "QUOTA_EXCEEDED_ERR"
        console.error "QUOTA_EXCEEDED_ERR catch BEGIN"
        console.error "Key: #{key}"
        console.error "Data: #{data}"
        console.error "QUOTA_EXCEEDED_ERR catch END"
      else
        # localStorage not available
    data
  getLocalStorage: (key) =>
    strData = root.localStorage.getItem(key)
    jsonData = if strData? then JSON.parse(strData) else null
    jsonData
  clearLocalStorage: =>
    root.localStorage.clear()
  setSortedProjectsLS: (account, projectIds) =>
    @setLocalStorage("sorted_projects_#{account.id}", projectIds)
  getSortedProjectsLS: (account) =>
    @getLocalStorage("sorted_projects_#{account.id}")
    
  # OPTIONS
  getAllOptionsLS: =>
    storiesTabView = @getStoriesTabViewLS()
    storiesUserView = @getStoriesUserViewLS()
    options = 
      updateInterval: @getUpdateIntervalLS()
      storiesUserView: storiesUserView
      storiesTabView: storiesTabView
    switch storiesTabView
      when "current"
        _.extend(options, {currentStoriesTabView: true})
      when "done"
        _.extend(options, {doneStoriesTabView: true})
      when "icebox"
        _.extend(options, {iceboxStoriesTabView: true})
      else
        _.extend(options, {allStoriesTabView: true})
    switch storiesUserView
      when "owner"
        _.extend(options, {ownerStoriesUserView: true})
      when "requester"
        _.extend(options, {requesterStoriesUserView: true})
      else
        _.extend(options, {allStoriesUserView: true})
    options
  getStoriesTabViewLS: =>
    @getLocalStorage("stories_tab_view") || "all"
  setStoriesTabViewLS: (value) =>
    @setLocalStorage("stories_tab_view", value)
  getStoriesUserViewLS: =>
    @getLocalStorage("stories_user_view") || "all"
  setStoriesUserViewLS: (value) =>
    @setLocalStorage("stories_user_view", value)
  getUpdateIntervalLS: =>
    defInterval = 15
    interval = @getLocalStorage("update_interval") || defInterval
    interval = defInterval if interval < defInterval
    interval
  setUpdateIntervalLS: (interval) =>
    @setLocalStorage("update_interval", interval)
