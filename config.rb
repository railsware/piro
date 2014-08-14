# encoding: utf-8
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
###
# Blog settings
###

Time.zone = "Kyiv"

###
# Compass
###

# Susy grids in Compass
# First: gem install susy --pre
# require 'susy'

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy (fake) files
# page "/this-page-has-no-template.html", :proxy => "/template-file.html" do
#   @which_fake_page = "Rendering a fake page with a variable"
# end

###
# Helpers
###

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Methods defined in the helpers block are available in templates
# helpers do
#   def some_helper
#     "Helping"
#   end
# end

set :css_dir, 'css'
set :js_dir, 'js'
set :images_dir, 'images'
set :markdown_engine, :redcarpet
set :markdown, filter_html: false, fenced_code_blocks: true, smartypants: true
set :encoding, "utf-8"
# highlight
#activate :syntax, linenos: 'inline', anchorlinenos: true, linenostart: 2
# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  activate :minify_css

  # Minify Javascript on build
  activate :minify_javascript

  # Enable cache buster
  # activate :cache_buster

  # Use relative URLs
  # activate :relative_assets

  # Compress PNGs after build
  # First: gem install middleman-smusher
  #require "middleman-smusher"
  #activate :smusher

  # Or use a different image path
  # set :http_path, "/Content/images/"
  #
  activate :asset_hash, ignore: %r{^images/static/.*}
  # min html
  activate :minify_html
end
# autoprefixer
activate :autoprefixer do |config|
  config.browsers = ['last 2 versions', 'Explorer >= 9']
  config.cascade  = false
end
# deploy
activate :deploy do |deploy|
  deploy.method = :git
  deploy.branch = "gh-pages"
  deploy.clean = true
end
