# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :shell do
  watch(%r{^assets/javascripts/(.+)\.coffee$}) do
    msg = `bundle exec rake`
    n msg, 'PiRo'
    "-> #{msg}"
  end
end