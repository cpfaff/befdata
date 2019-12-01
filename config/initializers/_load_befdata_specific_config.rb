# frozen_string_literal: true

EML_CONFIG = YAML.load_file("#{Rails.root}/config/configuration.yml")['eml'].try(:with_indifferent_access) || {}
SITE_CONFIG = YAML.load_file("#{Rails.root}/config/configuration.yml")['site'].try(:with_indifferent_access) || {}
