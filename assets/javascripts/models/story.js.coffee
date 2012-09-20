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
