# frozen_string_literal: true

# tested with ruby 2.3.8
ruby '2.3.8'

source 'https://rubygems.org'

# the rails framework:
# gem 'rails', '~> 4.2.0'
gem 'rails', '~> 5.0.0'

# the postgres db connector
gem 'pg', '~> 1.2.3'

# a templating engine for html
gem 'haml', '~> 5.1.2'

# authentication solution
gem 'authlogic', '~> 4.4.3'

# role-based authorization system
# gem 'acl9', '~> 2.1.2'
gem 'acl9', '~> 3.0'

# upload management for active record
gem 'paperclip', '~> 6.1.0'

# tag a single model on several contexts
gem 'acts-as-taggable-on', '~> 5.0.0'

# read and write spreadsheet documents
gem 'spreadsheet', '~> 1.2.5'

# active record backend for Delayed::Job
gem 'delayed_job_active_record', '~> 4.1.0'

# wrap ruby scripts executed as deamon
gem 'daemons', '~> 1.3.1'

# writing and deploying cron jobs
gem 'whenever', '~> 1.0.0', require: false

# bulk inserting data using active record
gem 'activerecord-import', '~> 1.0.0'

# named scoples for postgres fulltext search
gem 'pg_search', '~> 2.1.0'

# sass adapter
gem 'sass-rails', '~> 5.0.0'

# for new ui

# bootstrap
gem 'bootstrap', '~> 4.4.1'

# select for bootstrap
gem 'bootstrap-select-rails', '~> 1.13.8'

# data tables
gem 'jquery-datatables', '~> 1.10.20'

# font awesome
gem 'font_awesome5_rails', '~> 1.0.0'

# simple form
gem 'simple_form', '~> 5.0.1'

# clipboard functionality
gem 'clipboard-rails', '~> 1.7.1'

# jQuery and the jQuery-ujs driver for your Rails
gem 'jquery-rails', '~> 4.3.0'

# jQuery UI's JavaScript, CSS, and image files
gem 'jquery-ui-rails', '~> 6.0.0'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5.2.1'

# pagination
gem 'pagy', '~> 3.7'

# coffee script adapter
gem 'coffee-rails', '~> 4.1.0'

# upgrade path
# assigns and assert_template in tests
gem 'rails-controller-testing', '~> 1.0.4'

group :production do
  # maintenance mode
  gem 'turnout', '~> 2.5.0'

  # monitoring tools
  # gem 'newrelic_rpm'
end

# uglifier minifies java script
gem 'uglifier', '~> 2.7.2'

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'

  # unit testing framework
  # gem 'test-unit', '~> 3.3.4'

  # parallelize tests
  # gem 'parallel_tests', '~> 2.29.2'

  # hosted test coverage service (badge)
  gem 'coveralls', '~> 0.8.23', require: false
end

group :development do
  # find missing indexes
  # gem 'lol_dba', '~> 2.1.8'

  # bindings for the GNOME Libxml2
  gem 'libxml-ruby', '~> 3.1.0'

  # web server
  gem 'puma', '~> 4.3.0'

  # gem 'debugger'
  gem 'better_errors', '~> 2.5.1'

  # retrieve the binding of a method's caller
  gem 'binding_of_caller', '~> 0.8.0'

  # debug with a console 
  gem 'byebug'

  # code formatter
  gem 'rubocop', '~> 0.77.0', require: false

  # Spring speeds up development by keeping your application
  # running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 2.0.2'

  # Profiling toolkit
  # gem 'rack-mini-profiler', require: false
  gem 'bullet'

  # listen gem to detect on code changes
  gem 'listen', '>= 3.0.5', '< 3.2'

  # bundle exec rake doc:rails
  # generates the API under doc/api.
  gem 'sdoc', '~> 0.4.0'
end

