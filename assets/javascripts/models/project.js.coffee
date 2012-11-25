class PiroPopup.Models.Project extends Backbone.Model
  initialize: (attributes) =>
    @stories = new PiroPopup.Collections.Stories
    if attributes.stories?
      @stories.reset(attributes.stories)
      @unset("stories")

  setStories: (stories) =>
    @stories.reset(stories)
    
  toJSON: =>
    attr = _.clone(@attributes)
    attr.pointScaleArray = attr.point_scale.split(",") if attr.point_scale?
    attr