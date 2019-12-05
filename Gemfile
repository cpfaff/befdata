# frozen_string_literal: true

# tested with ruby 2.3.3

source 'https://rubygems.org'

# the rails framework:
gem 'rails', '~> 4.2.0'

# the gem was vulnerable thus i explicitly set
# it here to update it.
gem 'rails-html-sanitizer', '~> 1.0.3'

# the postgres db connector
gem 'pg', '~> 0.18.0'

# a templating engine for html
gem 'haml', '~> 3.1.7'

# authentication solution
gem 'authlogic', '~> 3.4.0'

# role-based authorization system
gem 'acl9', '~> 1.0.0'

# helper methods for rails 3 models
gem 'dynamic_form', '~> 1.1.4'

# upload management for active record
gem 'paperclip', '~> 5.2.0'

# tag a single model on several contexts
gem 'acts-as-taggable-on', '~> 5.0.0'

# read and write spreadsheet documents
gem 'spreadsheet', '~> 1.2.5'

# active record backend for Delayed::Job
gem 'delayed_job_active_record', '~> 4.1.0'

# wrap ruby scripts executed as deamon
gem 'daemons', '~> 1.1.9'

# writing and deploying cron jobs
gem 'whenever', '~> 0.8.2', require: false

# bulk inserting data using active record
gem 'activerecord-import', '~> 1.0.3'

# named scoples for postgres fulltext search
gem 'pg_search', '~> 2.0.0'

# jQuery and the jQuery-ujs driver for your Rails
gem 'jquery-rails', '~> 3.1.3'

# jQuery UI's JavaScript, CSS, and image files
gem 'jquery-ui-rails', '~> 3.0.1'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5.2.1'

# paginated queries with Active Record
gem 'will_paginate', '~> 3.0.5'

# sass adapter
gem 'sass-rails', '~> 4.0.0'

# coffee script adapter
gem 'coffee-rails', '~> 4.0.0'

group :production do
  # maintenance mode
  gem 'turnout', '~> 2.5.0'

  # monitoring tools
  # gem 'newrelic_rpm'
end

# uglifier minifies java script
gem 'uglifier', '~> 2.7.2'

group :test, :development do
  # unit testing framework
  gem 'test-unit', '~> 3.3.4'

  # find missing indexes
  gem 'lol_dba', '~> 2.1.8'

  # parallelize tests
  gem 'parallel_tests', '~> 2.29.2'

  # bindings for the GNOME Libxml2
  gem 'libxml-ruby', '~> 3.1.0'

  # web server
  gem 'thin', '~> 1.7.0'

  # gem 'debugger'
  gem 'better_errors', '~> 2.5.1'

  # retrieve the binding of a method's caller
  gem 'binding_of_caller', '~> 0.8.0'

  # hosted test coverage service (badge)
  gem 'coveralls', '~> 0.8.23', require: false

  # code formatter
  gem 'rubocop', '~> 0.77.0', require: false

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', '~> 11.0.1'
   
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 2.0.2'

  # Profiling toolkit
  # gem 'rack-mini-profiler', require: false
end

# bundle exec rake doc:rails generates the API under doc/api.
# gem 'sdoc', '~> 0.4.0', group: :doc
