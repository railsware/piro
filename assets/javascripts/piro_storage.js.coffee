root = global ? window

class root.PiroStorage
  constructor: (params = {}) ->
    @dbName = "piro"
    @dbVersion = "1"
    @db = null
    @indexedDB = root.indexedDB || root.webkitIndexedDB || root.mozIndexedDB
    root.IDBTransaction ||= root.webkitIDBTransaction
    root.IDBKeyRange ||= root.webkitIDBKeyRange
    @transactionPermitions = 
      READ_WRITE : "readwrite"
      READ_ONLY : "readonly"
    request = @indexedDB.open(@dbName, @dbVersion)
    request.onerror = @_dbError
    request.onupgradeneeded = (e) =>
      @_initDbFinished(e, params, true)
    request.onsuccess = (e) =>
      @_initDbFinished(e, params)
  _initDbFinished: (e, params, isMigrate = false) =>
    @db = e.target.result
    @_migrateDb() if isMigrate is true
    params.success.call(null) if params.success?
  _migrateDb: =>
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
    trans = @db.transaction([@accountsKey()], @transactionPermitions.READ_ONLY)
    store = trans.objectStore(@accountsKey())
    keyRange = IDBKeyRange.lowerBound(0)
    cursorRequest = store.openCursor(keyRange)
    cursorRequest.onerror = @_dbError
    cursorRequest.onsuccess = (e) =>
      cursor = e.target.result
      if cursor?
        accounts.push(cursor.value)
        cursor.continue()
      else
        params.success.call(null, accounts) if params.success?
  saveAccount: (account, params = {}) =>
    trans = @db.transaction([@accountsKey()], @transactionPermitions.READ_WRITE)
    store = trans.objectStore(@accountsKey())
    request = store.put account
    request.onerror = @_dbError
    request.onsuccess = (e) =>
      params.success.call(null) if params.success?
  saveAccountAndGetAll: (account, params = {}) =>
    @saveAccount account, 
      success: =>
        @getAccounts
          success: (accounts) =>
            params.success.call(null, accounts) if params.success?
  deleteAccount: (accountId, params = {}) =>
    trans = @db.transaction([@accountsKey()], @transactionPermitions.READ_WRITE)
    store = trans.objectStore(@accountsKey())
    request = store.delete(accountId)
    request.onerror = @_dbError
    request.onsuccess = (e) =>
      data = e.target.result
      params.success.call(null, data) if params.success?
  # PROJECTS
  getAllProjects: (params = {}) =>
    projects = []
    trans = @db.transaction([@projectsKey()], @transactionPermitions.READ_ONLY)
    store = trans.objectStore(@projectsKey())
    keyRange = IDBKeyRange.lowerBound(0)
    cursorRequest = store.openCursor(keyRange)
    cursorRequest.onerror = @_dbError
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
    trans = @db.transaction([@projectsKey()], @transactionPermitions.READ_ONLY)
    store = trans.objectStore(@projectsKey())
    request = store.get(account.id)
    request.onerror = @_dbError
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
    trans = @db.transaction([@projectsKey()], @transactionPermitions.READ_WRITE)
    store = trans.objectStore(@projectsKey())
    data = 
      account_id: account.id
      projects: projects
    request = store.put data
    request.onerror = @_dbError
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
  setStory: (story, params = {}) =>
    trans = @db.transaction([@storiesKey()], @transactionPermitions.READ_WRITE)
    store = trans.objectStore(@storiesKey())
    request = store.put story
    request.onerror = @_dbError
    request.onsuccess = (e) =>
      data = e.target.result
      params.success.call(null, story) if params.success?
  setStories: (stories, params = {}) =>
    trans = @db.transaction([@storiesKey()], @transactionPermitions.READ_WRITE)
    store = trans.objectStore(@storiesKey())
    for story in stories
      request = store.put story
      request.onerror = @_dbError
  getStoryById: (storyId, params = {}) =>
    trans = @db.transaction([@storiesKey()], @transactionPermitions.READ_ONLY)
    store = trans.objectStore(@storiesKey())
    request = store.get(storyId)
    request.onerror = @_dbError
    request.onsuccess = (e) =>
      data = e.target.result
      params.success.call(null, data) if params.success?
  getStoriesByProject: (project, params = {}) =>
    stories = []
    trans = @db.transaction([@storiesKey()], @transactionPermitions.READ_ONLY)
    store = trans.objectStore(@storiesKey())
    index = store.index("project_id")
    projectIdVal = IDBKeyRange.only(project.id.toString())
    cursorRequest = index.openCursor(projectIdVal)
    cursorRequest.onerror = @_dbError
    cursorRequest.onsuccess = (e) =>
      cursor = e.target.result
      if cursor?
        stories.push(cursor.value)
        cursor.continue()
      else
        params.success.call(null, project, stories) if params.success?
  getStories: (params = {}) =>
    stories = []
    trans = @db.transaction([@storiesKey()], @transactionPermitions.READ_ONLY)
    store = trans.objectStore(@storiesKey())
    keyRange = IDBKeyRange.lowerBound(0)
    cursorRequest = store.openCursor(keyRange)
    cursorRequest.onerror = @_dbError
    cursorRequest.onsuccess = (e) =>
      cursor = e.target.result
      if cursor?
        stories.push(cursor.value)
        cursor.continue()
      else
        params.success.call(null, stories) if params.success?
  deleteStoryById: (storyId, params = {}) =>
    trans = @db.transaction([@storiesKey()], @transactionPermitions.READ_WRITE)
    store = trans.objectStore(@storiesKey())
    request = store.delete(storyId)
    request.onerror = @_dbError
    request.onsuccess = (e) =>
      data = e.target.result
      params.success.call(null, data) if params.success?
  # PROJECT ICONS
  getProjectIcons: (params = {}) =>
    icons = []
    trans = @db.transaction([@projectsIconsKey()], @transactionPermitions.READ_ONLY)
    store = trans.objectStore(@projectsIconsKey())
    keyRange = IDBKeyRange.lowerBound(0)
    cursorRequest = store.openCursor(keyRange)
    cursorRequest.onerror = @_dbError
    cursorRequest.onsuccess = (e) =>
      cursor = e.target.result
      if cursor?
        icons.push(cursor.value)
        cursor.continue()
      else
        params.success.call(null, icons) if params.success?
  getProjectIcon: (project, params = {}) =>
    icon = null
    trans = @db.transaction([@projectsIconsKey()], @transactionPermitions.READ_ONLY)
    store = trans.objectStore(@projectsIconsKey())
    keyRange = IDBKeyRange.only(project.id.toString())
    cursorRequest = store.openCursor(keyRange)
    cursorRequest.onerror = @_dbError
    cursorRequest.onsuccess = (e) =>
      cursor = e.target.result
      params.success.call(null, cursor.value) if params.success?
  saveProjectIcon: (project, icon, params = {}) =>
    trans = @db.transaction([@projectsIconsKey()], @transactionPermitions.READ_WRITE)
    store = trans.objectStore(@projectsIconsKey())
    request = store.put 
      id: project.id
      icon: icon
    request.onerror = @_dbError
    request.onsuccess = (e) =>
      params.success.call(null) if params.success?
  deleteProjectIcon: (projectId, params = {}) =>
    trans = @db.transaction([@projectsIconsKey()], @transactionPermitions.READ_WRITE)
    store = trans.objectStore(@projectsIconsKey())
    request = store.delete(projectId)
    request.onerror = @_dbError
    request.onsuccess = (e) =>
      data = e.target.result
      params.success.call(null, data) if params.success?
  # UTILS
  _dbError: (e) =>
    console.error "IndexedDB error begin"
    console.error e
    console.error "Error code: #{e.target.errorCode}"
    console.error "IndexedDB error end"
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
  deleteLocalStorageKey: (key) =>
    root.localStorage.removeItem(key)
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
      sortMoscow: @getMoscowSortLS()
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
  getStoryTitleTmpLS: =>
    storyTitle = @getLocalStorage("tmp_story_title")
    @deleteLocalStorageKey("tmp_story_title") if storyTitle?
    storyTitle
  setStoryTitleTmpLS: (value) =>
    @setLocalStorage("tmp_story_title", value)
  getStoriesUserViewLS: =>
    @getLocalStorage("stories_user_view") || "all"
  setStoriesUserViewLS: (value) =>
    @setLocalStorage("stories_user_view", value)
  getMoscowSortLS: =>
    @getLocalStorage("sort_stories_moscow") || false
  setMoscowSortLS: (value) =>
    @setLocalStorage("sort_stories_moscow", value)
  getUpdateIntervalLS: =>
    defInterval = 30
    interval = @getLocalStorage("update_interval") || defInterval
    interval = defInterval if interval < defInterval
    interval
  setUpdateIntervalLS: (interval) =>
    @setLocalStorage("update_interval", interval)
  getLatestProjectIdLS: =>
    @getLocalStorage("latest_project_id") || 0
  setLatestProjectIdLS: (value) =>
    @setLocalStorage("latest_project_id", value)
  getIsCommentOpenLS: =>
    @getLocalStorage("is_comment_open") || false
  setIsCommentOpenLS: (value) =>
    @setLocalStorage("is_comment_open", value)
  getIsTaskOpenLS: =>
    @getLocalStorage("is_task_open") || false
  setIsTaskOpenLS: (value) =>
    @setLocalStorage("is_task_open", value)