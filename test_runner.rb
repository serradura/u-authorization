# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'u-test', '0.8.0'
end

require_relative 'permissions'

require_relative 'test_permissions_features_checker'
require_relative 'test_permissions_policy'
require_relative 'test_permissions_model'

Microtest.call

