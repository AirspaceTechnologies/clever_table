require 'yaml'
us = YAML.load_file File.expand_path("../../data/users.yml", __FILE__)

FactoryGirl.define do
  factory(:user) do |u|
    u.sequence(:id) { |n| n }
      u.sequence(:name) { |n| "#{us[us.keys[n - 1]]['name']}" }
      u.sequence(:birthdate) { |n| "#{us[us.keys[n - 1]]['birthdate']}" }

  end
end