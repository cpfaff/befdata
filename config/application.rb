require_relative 'boot'

require 'rails/all'
require 'csv'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Configure environment variables
CONFIG = YAML.safe_load(File.read(File.expand_path('application.yml', __dir__)))
CONFIG.merge! CONFIG.fetch(Rails.env, {})
CONFIG.symbolize_keys!

module Befchina
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Halting Callback Chains via throw(:abort)
    ActiveSupport.halt_callback_chains_on_return_false = false

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    ActsAsTaggableOn.remove_unused_tags = true
    config.action_view.sanitized_allowed_tags = %w[strong em i b sup sub]
  end
end
