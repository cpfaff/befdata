# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# Create default roles:
# 'pi', ...

require 'active_record/fixtures'

puts '-- Loading seed fixtures'
seed_fixtures_path = (Rails.root.to_s + '/db/seed_fixtures').to_s
Dir.glob(seed_fixtures_path + '/*.yml').each do |file|
  ActiveRecord::FixtureSet.create_fixtures(seed_fixtures_path, File.basename(file, '.*'))
end
