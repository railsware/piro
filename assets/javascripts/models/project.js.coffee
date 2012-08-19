class PiroPopup.Models.Project extends Backbone.Model
  initialize: (attributes) =>
    @stories = new PiroPopup.Collections.Stories
    if attributes.stories?
      @stories.reset(attributes.stories)
      @unset("stories")