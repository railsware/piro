# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :shell do
  watch(%r{^assets/javascripts/(.+)\.coffee$}) do
    msg = `bundle exec rake pack:js_compile`
    if $?.success?
      Notifier.notify(msg, :title => 'PiRo', :image => :success, :priority => -2)
    else
      Notifier.notify(msg, :title => 'PiRo', :image => :failed, :priority => 2)
    end
    "-> #{msg}"
  end
  watch(%r{^assets/stylesheets/(.+)\.css$}) do
    msg = `bundle exec rake pack:css_compile`
    if $?.success?
      Notifier.notify(msg, :title => 'PiRo', :image => :success, :priority => -2)
    else
      Notifier.notify(msg, :title => 'PiRo', :image => :failed, :priority => 2)
    end
    "-> #{msg}"
  end
end