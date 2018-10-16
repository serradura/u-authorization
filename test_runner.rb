# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'u-test', '0.8.0'
end

require_relative 'authorization'

require_relative 'test_authorization_permissions'
require_relative 'test_authorization_policy'
require_relative 'test_authorization_model'

Microtest.call

