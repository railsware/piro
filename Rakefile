#!/usr/bin/env rake
require 'rake'
require 'coffee-script'
require 'uglifier'

desc 'Default: compress js and css.'
task :default => :'pack:default'

#########################################
### JS and CSS tasks
#########################################

namespace :pack do
  desc "do all pack tasks"
  task :default => [:compile]
  
  desc "compile coffee-scripts from ./assets/javascripts to ./javascripts"
  task :compile do
    source = "#{File.dirname(__FILE__)}/assets/javascripts/"
    javascripts = "#{File.dirname(__FILE__)}/javascripts/"
    
    Dir.foreach(source) do |cf|
      unless cf == '.' || cf == '..' 
        js_compiled = CoffeeScript.compile File.read("#{source}#{cf}")
        js = Uglifier.compile js_compiled
        open "#{javascripts}#{cf.gsub('.coffee', '.js')}", 'w' do |f|
          f.puts js
        end 
      end 
    end
    
    puts "All done."
  end
end

begin
  require 'jasmine'
  load 'jasmine/tasks/jasmine.rake'
rescue LoadError
  task :jasmine do
    abort "Jasmine is not available. In order to run jasmine, you must: (sudo) gem install jasmine"
  end
end

