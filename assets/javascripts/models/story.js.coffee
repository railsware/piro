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
    if "#" == text[0]
      if @has('labels')? && @get('labels').length > 0
        search = new RegExp(@_filterStrForRegex(text).substr(1), "gi")
        return (@get('labels').match(search)? and @get('labels').match(search).length)
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