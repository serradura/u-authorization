# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'u-test', '0.8.0'
end

require_relative 'permissions'

require 'json'

class TestPermissions < Microtest::Test
  def setup_all
    json = self.class.const_get(:ROLE).tap(&method(:puts))

    @role = JSON.parse(json)

    @start_time = Time.now
  end

  def build_permissions(context)
    Permissions.new @role['features'], context: context
  end

  def teardown_all
    print 'Elapsed time in milliseconds: '
    puts (Time.now - @start_time) * 1000.0
    puts ''
  end
end

class TestAdminPermissions < TestPermissions
  ROLE = <<~JSON
    {
      "role": "admin",
      "features": {
        "read": { "any": true },
        "save": { "any": true },
        "export_as_csv": { "any": true }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')
    permissions2 = build_permissions(['home'])

    assert permissions1.can?('read')
    assert permissions2.can?(['read'])
    assert permissions2.can?(['read', 'save'])
    assert permissions1.can?('export_as_csv')

    refute permissions1.cannot?('read')
    refute permissions2.cannot?(['read'])
    refute permissions2.cannot?(['read', 'save'])
    refute permissions1.cannot?(['export_as_csv'])
  end
end

module ReadOnlyRoles
  A = <<~JSON
    {
      "role": "readonly",
      "features": {
        "read": { "any": true }
      }
    }
  JSON

  B = <<~JSON
    {
      "role": "readonly2",
      "features": {
        "read": { "any": true },
        "save": { "any": false },
        "export_as_csv": { "any": false }
      }
    }
  JSON
end

class TestReadonlyPermissions < TestPermissions
  def call_features_test
    permissions1 = build_permissions('home')
    permissions2 = build_permissions(['home'])

    assert permissions1.can?('read')
    assert permissions2.can?(['read'])
    refute permissions1.cannot?('read')
    refute permissions2.cannot?(['read'])

    refute permissions2.can?(['read', 'save'])
    assert permissions2.cannot?(['read', 'save'])

    refute permissions1.can?('export_as_csv')
    assert permissions1.cannot?(['export_as_csv'])
  end
end

class TestReadonlyAPermissions < TestReadonlyPermissions
  ROLE = ReadOnlyRoles::A
  alias_method :test_role_permissions, :call_features_test
end

class TestReadonlyBPermissions < TestReadonlyPermissions
  ROLE = ReadOnlyRoles::B
  alias_method :test_role_permissions, :call_features_test
end

class TestUser0Permissions < TestPermissions
  ROLE = <<~JSON
    {
      "role": "user0",
      "features": {
        "read": { "any": true },
        "export_as_csv": { "only": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    assert permissions1.can?('read')
    assert permissions1.can?(['read'])
    refute permissions1.can?('export_as_csv')

    permissions2 = build_permissions(['sales'])

    assert permissions2.can?(['read'])
    assert permissions2.can?(['read', 'export_as_csv'])
    assert permissions2.can?('export_as_csv')
  end
end

class TestUser1Permissions < TestPermissions
  ROLE = <<~JSON
    {
      "role": "user1",
      "features": {
        "read": { "only": ["sales", "commissionings", "releases"] },
        "export_as_csv": { "only": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    refute permissions1.can?('read')
    refute permissions1.can?('export_as_csv')

    permissions2 = build_permissions('sales')

    assert permissions2.can?('read')
    assert permissions2.can?('export_as_csv')
    assert permissions2.can?(['read', 'export_as_csv'])

    permissions3 = build_permissions('commissionings')

    assert permissions3.can?('read')
    refute permissions3.can?('export_as_csv')
    refute permissions3.can?(['read', 'export_as_csv'])

    permissions4 = build_permissions('commissionings')

    assert permissions4.can?('read')
    refute permissions4.can?('export_as_csv')
    refute permissions4.can?(['read', 'export_as_csv'])
  end
end

class TestUser2Permissions < TestPermissions
  ROLE = <<~JSON
    {
      "role": "user2",
      "features": {
        "read": { "only": ["sales", "commissionings", "releases"] },
        "export_as_csv": { "except": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    refute permissions1.can?('read')
    assert permissions1.can?('export_as_csv') # Warning!!!

    permissions2 = build_permissions('sales')

    assert permissions2.can?('read')
    refute permissions2.can?('export_as_csv')
    refute permissions2.can?(['read', 'export_as_csv'])

    permissions3 = build_permissions('commissionings')

    assert permissions3.can?('read')
    assert permissions3.can?('export_as_csv')
    assert permissions3.can?(['read', 'export_as_csv'])

    permissions4 = build_permissions('commissionings')

    assert permissions4.can?('read')
    assert permissions4.can?('export_as_csv')
    assert permissions4.can?(['read', 'export_as_csv'])
  end
end

class TestUser3Permissions < TestPermissions
  ROLE =  <<~JSON
    {
      "role": "user3",
      "features": {
        "read": { "except": ["sales"] },
        "export_as_csv": { "except": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    assert permissions1.can?('read')
    assert permissions1.can?('export_as_csv')

    permissions2 = build_permissions('sales')

    refute permissions2.can?('read')
    refute permissions2.can?('export_as_csv')
    refute permissions2.can?(['read', 'export_as_csv'])

    permissions3 = build_permissions('commissionings')

    assert permissions3.can?('read')
    assert permissions3.can?('export_as_csv')
    assert permissions3.can?(['read', 'export_as_csv'])

    permissions4 = build_permissions('commissionings')

    assert permissions4.can?('read')
    assert permissions4.can?('export_as_csv')
    assert permissions4.can?(['read', 'export_as_csv'])
  end
end

class TestPermissionsToHanamiClasses < TestPermissions
  module Dashboard
    module Controllers
      module Sales
        class Index
        end
      end
    end

    module Views
      module Sales
        class Index
        end
      end
    end
  end

  ROLE = <<~JSON
    {
      "role": "hanami_classes",
      "features": {
        "read": { "any": true },
        "export_as_csv": { "except": ["sales.index"] }
      }
    }
  JSON

  def extract_permissions_context_from_hanami_class(klass)
    klass.name.downcase.split('::').tap do |context|
      puts "Context: #{context.inspect}"
    end
  end

  def test_role_permissions
    controller_context = extract_permissions_context_from_hanami_class(
      Dashboard::Controllers::Sales::Index
    )

    permissions1 = build_permissions(controller_context)

    assert permissions1.can?('read')
    refute permissions1.can?('export_as_csv')

    view_context = extract_permissions_context_from_hanami_class(
      Dashboard::Views::Sales::Index
    )

    permissions2 = build_permissions(view_context)

    assert permissions2.can?('read')
    refute permissions2.can?('export_as_csv')
  end
end

class TestPermissionsCacheStrategy < TestPermissions
  ROLE = <<~JSON
    {
      "role": "cache_strategy",
      "features": {
        "read": { "any": ["true"] },
        "save": { "except": ["sales"] }
      }
    }
  JSON

  def test_cache_with_single_feature_verification
    permissions = build_permissions(['sales'])

    assert permissions.can?('read')
    refute permissions.can?('save')

    def permissions.permitted?(_feature_context); raise; end

    assert permissions.can?('read')
    refute permissions.can?('save')
  end

  def test_cache_with_multiple_features_verification
    permissions = build_permissions(['sales'])

    assert permissions.can?('read')
    assert permissions.cannot?(['read', 'save'])

    def permissions.permitted?(_feature_context); raise; end

    assert permissions.can?('read')
    assert permissions.cannot?(['read', 'save'])
  end
end

Microtest.call
