class PiroPopup.Views.ProjectsSettings extends Backbone.View
  template: SHT['projects/settings']
  events:
    "click .close_settings"                 : "closeSettings"
    "change .project_upload_icon"           : "uploadIconFile"
  
  initialize: =>
    @model.on 'change', @render
    @model.on 'destroy', @remove
    # avatars
    @fileReader = new FileReader()
    @imgFilter = /^(?:image\/bmp|image\/cis\-cod|image\/gif|image\/ief|image\/jpeg|image\/jpeg|image\/jpeg|image\/pipeg|image\/png|image\/svg\+xml|image\/tiff|image\/x\-cmu\-raster|image\/x\-cmx|image\/x\-icon|image\/x\-portable\-anymap|image\/x\-portable\-bitmap|image\/x\-portable\-graymap|image\/x\-portable\-pixmap|image\/x\-rgb|image\/x\-xbitmap|image\/x\-xpixmap|image\/x\-xwindowdump)$/i
    @fileReader.onload = @fileUploaded

  render: =>
    $(@el).html(@template.render(@model.toJSON()))
    this
    
  uploadIconFile: (e) =>
    e.preventDefault()
    return false if @$(".project_upload_icon")[0].files.length is 0
    file = @$(".project_upload_icon")[0].files[0]
    return false unless @imgFilter.test(file.type)
    return false if file.size > 307200
    @fileReader.readAsDataURL(file)
    
  fileUploaded: (e) =>
    return false unless e.target? && e.target.result?
    PiroPopup.db.saveProjectIcon @model.toJSON(), e.target.result, 
      success: =>
        @$('.project_icon').attr('src', e.target.result)
        @model.set(icon: e.target.result)
  
  closeSettings: (e) =>
    e.preventDefault()
    PiroPopup.dialogContainer().dialog('close')
  
  remove: =>
    $(@el).remove()
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove
