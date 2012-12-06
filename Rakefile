require 'rubygems'
require 'bundler'

Bundler.require
require './lib/app'
require 'erb'
require 'tilt'

namespace :assets do
  desc 'compile all data'
  task :compile => [:compile_js, :compile_css, :compile_html] do
  end

  desc 'compile javascript assets'
  task :compile_js do
    begin
      sprockets = PiroServer.settings.sprockets
      outpath   = PiroServer.settings.assets_path
      # 1 stage
      asset     = sprockets['application.js']
      outfile   = Pathname.new(outpath).join("application.min.js") # may want to use the digest in the future?
      FileUtils.mkdir_p outfile.dirname
      asset.write_to(outfile)
      # 2 stage
      asset     = sprockets['background.js']
      outfile   = Pathname.new(outpath).join("background.min.js") # may want to use the digest in the future?
      FileUtils.mkdir_p outfile.dirname
      asset.write_to(outfile)
      # 3 stage
      asset     = sprockets['options.js']
      outfile   = Pathname.new(outpath).join("options.min.js") # may want to use the digest in the future?
      FileUtils.mkdir_p outfile.dirname
      asset.write_to(outfile)
      # 4 stage
      asset     = sprockets['popup.js']
      outfile   = Pathname.new(outpath).join("popup.min.js") # may want to use the digest in the future?
      FileUtils.mkdir_p outfile.dirname
      asset.write_to(outfile)
      puts "successfully compiled js assets"
    rescue => e
      puts "failed compile js assets. Error: #{e.message}"
    end
  end

  desc 'compile css assets'
  task :compile_css do
    begin
      sprockets = PiroServer.settings.sprockets
      outpath   = PiroServer.settings.assets_path
      # 1 stage
      asset     = sprockets['application.css']
      outfile   = Pathname.new(outpath).join("application.min.css") # may want to use the digest in the future?
      FileUtils.mkdir_p outfile.dirname
      asset.write_to(outfile)
      puts "successfully compiled css assets"
    rescue => e
      puts "failed compile css assets. Error: #{e.message}"
    end
  end
  
  desc 'compile html assets'
  task :compile_html do
    begin
      # helpers
      include AssetHelpers
    
      def erb(template, options={}, locals={}, &block)
        templateEngine = Tilt[:erb].new(File.join(File.dirname(__FILE__), 'lib', 'views', "#{template}.erb"), 1, options)
        templateEngine.render({}, locals, &block)
      end
      # HTML
      outpath   = File.join(File.dirname(__FILE__))
      html_compressor = HtmlCompressor::HtmlCompressor.new
      # html files
      %w(index.html options.html popup.html).each do |filename|
        html_body = erb(filename)
        html_body = html_compressor.compress(html_body) if ENV['RELEASE']
        File.open(File.join(outpath, filename), 'w') {|f| f.write(html_body) }
      end
      puts "successfully compiled html assets"
    rescue => e
      puts "failed compile html assets. Error: #{e.message}"
    end
  end
  # todo: add :clean_all, :clean_css, :clean_js tasks, invoke before writing new file(s)
end