class PiroPopup.Collections.Stories extends Backbone.Collection
  model: PiroPopup.Models.Story
  
  getStoriesByFilters: (filter) =>
    @filter (story) =>
      story.filterByState(filter.storiesTabView) and story.filterByUser(filter.account, filter.storiesUserView)