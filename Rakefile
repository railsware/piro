# encoding: utf-8
#!/usr/bin/env rake
require 'rake'
require 'coffee-script'
require 'uglifier'
require 'cssmin'

desc 'Default: compress js and css.'
task :default => :'pack:default'

#########################################
### JS and CSS tasks
#########################################

namespace :pack do
  desc "do all pack tasks"
  task :default => [:js_compile, :css_compile]
  
  desc "compile coffee-scripts from ./assets/javascripts to ./javascripts"
  task :js_compile do
    begin
      source = "#{File.dirname(__FILE__)}/assets/javascripts/"
      javascripts = "#{File.dirname(__FILE__)}/javascripts/"
  
      Dir.foreach(source) do |cf|
        unless cf == '.' || cf == '..'
          js_compiled = CoffeeScript.compile File.read("#{source}#{cf}") 
          if ENV['RELEASE']
            js = Uglifier.compile js_compiled
          else
            js = js_compiled
          end
          open "#{javascripts}#{cf.gsub('.coffee', '.js')}", 'w' do |f|
            f.puts js
          end 
        end 
      end
  
      puts "All coffescripts compiled successful!"
    rescue => e
      puts "Compilation error: #{e.inspect}"
      raise e
    end
  end
  
  desc "compile css from ./assets/stylesheets to ./stylesheets"
  task :css_compile do
    begin
      source = "#{File.dirname(__FILE__)}/assets/stylesheets/"
      stylesheets = "#{File.dirname(__FILE__)}/stylesheets/"
  
      Dir.foreach(source) do |cf|
        unless cf == '.' || cf == '..' 
          if ENV['RELEASE']
            css = CSSMin.minify File.read("#{source}#{cf}")
          else
            css = File.read("#{source}#{cf}")
          end
          open "#{stylesheets}#{cf}", 'w' do |f|
            f.puts css
          end 
        end 
      end
  
      puts "All css minified successful!"
    rescue => e
      puts "Minified error: #{e.inspect}"
      raise e
    end
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

