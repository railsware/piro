class PiroPopup.Models.Project extends Backbone.Model
  initialize: (attributes) =>
    @stories = new PiroPopup.Collections.Stories
    if attributes.stories?
      @stories.reset(attributes.stories)
      @unset("stories")

  setStories: (stories) =>
    @stories.reset(stories)
    
  sortedMemberships: =>
    memberships = @get('memberships')
    memberships = [] unless memberships?
    memberships = memberships.sort (a, b) =>
      if a.person? && a.person.name? &&
      b.person? && b.person.name?
        return -1 if (a.person.name < b.person.name)
        return 1 if (a.person.name > b.person.name)
      return 0
    memberships
    
  toJSON: =>
    attr = _.clone(@attributes)
    attr.pointScaleArray = attr.point_scale.split(",") if attr.point_scale?
    attr.sortedMemberships = @sortedMemberships()
    attr