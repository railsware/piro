class PiroPopup.Collections.Stories extends Backbone.Collection
  model: PiroPopup.Models.Story
  
  getStoriesByFilters: (filter) =>
    stories = @filter (story) =>
      story.filterByState(filter.storiesTabView) and story.filterByUser(filter.account, filter.storiesUserView) and story.filterByText(filter.filterText)
    if filter.sortMoscow? && filter.sortMoscow is true
      stories = _.sortBy(stories, @_sortByMoscow)
    else
      stories = _.sortBy(stories, @_sortByState)
    stories

  _sortByMoscow: (story) =>
    lowerIndex = 10
    return lowerIndex if !story.has("labels")? or story.get("labels").length is 0
    moscow = ["must", "should", "could", "wont"]
    labels = story.get("labels").replace("#", "").toLowerCase().split(",")
    for label in labels
      index = _.indexOf(moscow, label)
      lowerIndex = index if index isnt -1 and lowerIndex > index
    lowerIndex

  _sortByState: (story) =>
    _.indexOf(["accepted", "delivered", "finished", "started", "rejected", "unstarted", "unscheduled"], story.get('current_state').toLowerCase())