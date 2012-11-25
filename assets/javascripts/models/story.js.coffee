class PiroPopup.Models.Story extends Backbone.Model
  
  filterByState: (state) =>
    storyState = @get("current_state")
    return switch state
      when "current"
        storyState isnt "accepted" and storyState isnt "unscheduled"
      when "done"
        storyState is "accepted"
      when "icebox"
        storyState is "unscheduled"
      else
        true
      
  filterByUser: (account, userView) =>
    accountId = parseInt(account.get("id"))
    switch userView
      when "owner"
        ownedBy = @get("owned_by")
        return false if !ownedBy? or !ownedBy.id?
        return parseInt(ownedBy.id) is accountId
      when "requester"
        requestedBy = @get("requested_by")
        return false if !requestedBy? or !requestedBy.id?
        return parseInt(requestedBy.id) is accountId
      else
        return true

  filterByText: (text) =>
    return true if !text? or (text? and 0 == text.length)
    switch text[0]
      when "#"
        if @has('labels')? && @get('labels').length > 0
          search = new RegExp(@_filterStrForRegex(text).substr(1), "gi")
          return (@get('labels').match(search)? and @get('labels').match(search).length)
        else
          return false
      when "@"
        if @has('owned_by')? && @get("owned_by").initials?
          return @_filterStrForRegex(text).substr(1) is @get("owned_by").initials
        else
          return false
      else
        search = new RegExp(@_filterStrForRegex(text), "gi")
        return (
          (@get('id').match(search)? and @get('id').match(search).length) or 
          (@get('name').match(search)? and @get('name').match(search).length) or 
          (@get('description').match(search)? and @get('description').match(search).length) or 
          (@get('current_state').match(search)? and @get('current_state').match(search).length)
        )
      
  
  _filterStrForRegex: (str) =>
    str.replace(/([.?*+^$[\]\\(){}|-])/g, "\\$1")

  toJSON: =>
    attr = _.clone(@attributes)
    attr = @_fixAttributes(attr)
    attr.tasks = @_fixTasks(attr.tasks) if attr.tasks.length > 0
    attr.comments = @_fixComments(attr.comments) if attr.comments.length > 0
    attr
  # private
  _fixAttributes: (attr = {}) =>
    attr.owned_by = null if attr.owned_by? and (!attr.owned_by.id? or attr.owned_by.id.length is 0)
    attr.requested_by = null if attr.requested_by? and (!attr.requested_by.id? or attr.requested_by.id.length is 0)
    attr.labelsList = attr.labels.split(",") if attr.labels? and attr.labels.length > 0
    attr.deadline = null if !attr.deadline? || attr.deadline.length is 0
    attr.descriptionHtml = attr.description.replace(/(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig, "<a class='description_link' target='_blank' href='$1'>$1</a>")
    switch @get('story_type').toLowerCase()
      when "feature"
        attr.isFeature = true
        attr.isFullStatus = true
        attr.isNeedEstimate = true if parseInt(attr.estimate) is -1
        switch @get("current_state").toLowerCase()
          when "unscheduled"
            attr.isUnscheduled = true
          else
            # none
      when "bug"
        attr.isBug = true
        attr.isFullStatus = true
      when "chore"
        attr.isChore = true
      when "release"
        attr.isRelease = true
      else
        # none
    attr
  _fixTasks: (tasks) =>
    fixedTasks = _.map tasks, (task) =>
      newTask = task
      newTask.complete = (task.complete.toString() is "true")
      newTask.position = parseInt(task.position)
      newTask
    _.sortBy(fixedTasks, (task) -> task.position)
  _fixComments: (comments) =>
    fixedComments = []
    fixedComments = _.map comments, (comment) =>
      newComment = comment
      return null if comment.text.length is 0
      newComment
    _.compact(fixedComments)