root = global ? window

class root.PivotaltrackerApi
  v3Url: "https://www.pivotaltracker.com/services/v3"
  baseUrl: "https://www.pivotaltracker.com/services/v4"
  # templates
  projectsTemplate: [ "//project", 
  { id: "id", name: "name", created_at: "created_at",
  version: "version", iteration_length: "iteration_length", week_start_day: "week_start_day",
  point_scale: "point_scale", account: "account", labels: "labels",
  public: "public", use_https: "use_https", velocity_scheme: "velocity_scheme",
  initial_velocity: "initial_velocity", current_velocity: "current_velocity", allow_attachments: "allow_attachments",
  memberships: ["memberships/membership", {id: "id", role: "role", 
  person: {id: "member/person/id", email: "member/person/email", name: "member/person/name", initials: "member/person/initials"}}]
  }]
  storiesTemplate: [ "//story", 
  { id: "id", project_id: "project_id", story_type: "story_type",
  url: "url", estimate: "estimate", current_state: "current_state",
  description: "description", name: "name", 
  requested_by: {id: "requested_by/person/id", name: "requested_by/person/name", initials: "requested_by/person/initials"},
  owned_by: {id: "owned_by/person/id", name: "owned_by/person/name", initials: "owned_by/person/initials"}, 
  created_at: "created_at", labels: "labels",
  comments: ["comments/comment", {id: "id", text: "text", created_at: "created_at", 
  author: {id: "author/person/id", name: "author/person/name", initials: "author/person/initials"}}],
  attachments: ["attachments/attachment", {id: "id", filename: "filename", uploaded_at: "uploaded_at", url: "url", 
  s3_resource: {url: "s3_resource/url", expires: "s3_resource/expires"},
  uploaded_by: {id: "uploaded_by/person/id", name: "uploaded_by/person/name", initials: "uploaded_by/person/initials"}}]
  }]
  # init
  constructor: (@account) ->
    # constructor
  sendPivotalRequest: (params) =>
    ajaxParams = 
      timeout: 80000
      dataType: 'xml'
      headers: 
        "X-TrackerToken": @account.token.guid
    ajaxParams.url         = params.url if params.url?
    ajaxParams.type        = params.type if params.type?
    ajaxParams.data        = params.data if params.data?
    ajaxParams.error       = params.error if params.error?
    ajaxParams.success     = params.success if params.success?
    ajaxParams.complete    = params.complete if params.complete?
    ajaxParams.beforeSend  = params.beforeSend if params.beforeSend?
    $.ajax ajaxParams
    
  getProjects: (params = {}) =>
    successFunction = params.success
    params.url = "#{@baseUrl}/projects"
    params.success = (data, textStatus, jqXHR) =>
      projects = Jath.parse(@projectsTemplate, data)
      successFunction.call(null, projects, textStatus, jqXHR) if successFunction?
    this.sendPivotalRequest(params)
  getStories: (project, params = {}) =>
    successFunction = params.success
    params.url = "#{@baseUrl}/projects/#{project.id}/stories"
    params.success = (data, textStatus, jqXHR) =>
      stories = Jath.parse(@storiesTemplate, data)
      successFunction.call(null, project, stories, textStatus, jqXHR) if successFunction?
    this.sendPivotalRequest(params)
  getStory: (storyId, params = {}) =>
    successFunction = params.success
    params.url = "#{@baseUrl}/stories/#{storyId}"
    params.success = (data, textStatus, jqXHR) =>
      stories = Jath.parse(@storiesTemplate, data)
      successFunction.call(null, stories, textStatus, jqXHR) if successFunction?
    this.sendPivotalRequest(params)
  createStory: (projectId, params = {}) =>
    successFunction = params.success
    errorFunction = params.error
    maxIterator = 8
    # worst API (500 on new api)
    params.url = "#{@v3Url}/projects/#{projectId}/stories"
    #params.url = "#{@baseUrl}/projects/#{projectId}/stories"
    params.type = "POST"
    params.success = (data, textStatus, jqXHR) =>
      stories = Jath.parse(@storiesTemplate, data)
      story = stories[0] if stories.length > 0
      return false unless story.id?
      @_getStoryWithTimeout(story, successFunction, errorFunction, maxIterator)
    this.sendPivotalRequest(params)
  deleteStory: (story, params = {}) =>
    successFunction = params.success
    params.url = "#{@baseUrl}/projects/#{story.project_id}/stories/#{story.id}"
    params.type = "DELETE"
    params.success = (data, textStatus, jqXHR) =>
      successFunction.call(null, data, textStatus, jqXHR) if successFunction?
    this.sendPivotalRequest(params)
  # private
  _getStoryWithTimeout: (story, successFunction, errorFunction, maxIterator) =>
    setTimeout(=>
      @getStory story.id, 
        success: (stories, textStatus, jqXHR) =>
          successFunction.call(null, stories, textStatus, jqXHR) if successFunction?
        error: =>
          maxIterator--
          if maxIterator > 0
            @_getStoryWithTimeout(story, successFunction, errorFunction, maxIterator)
          else
            errorFunction.call(null) if errorFunction?
    , 500)
# pivotal auth lib
class root.PivotaltrackerAuthLib
  baseUrl: "https://www.pivotaltracker.com/services/v4"
  constructor: (params = {}) ->
    ajaxParams = 
      cache: false
      global: false
      dataType: 'xml' 
      url: "#{this.baseUrl}/me"
      success: (data, textStatus, jqXHR) ->
        template = [ "//person", 
        { id: "id", email: "email", name: "name", initials: "initials", 
        "token": {id: "token/id", guid: "token/guid"}, 
        "time_zone": {name: "time_zone/name", code: "time_zone/code", offset: "time_zone/offset"}
        }]
        persons = Jath.parse(template, data)
        person = if persons? && persons.length > 0 then persons[0] else null
        params.success.call(null, person, textStatus, jqXHR) if params.success?
      error: params.error
      beforeSend: params.beforeSend
    if params.username? && params.password?
      ajaxParams.username = params.username
      ajaxParams.password = params.password
      ajaxParams.headers = 
        'Authorization': "Basic #{btoa(params.username + ":" + params.password)}"
    else
      ajaxParams.headers = 
        "X-TrackerToken": (params.token || null)
    $.ajax ajaxParams