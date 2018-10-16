# frozen_string_literal: true

class TestAuthorizationPermissions < Microtest::Test
  require 'json'

  def setup_all
    json = self.class.const_get(:ROLE).tap(&method(:puts))

    @role = JSON.parse(json)

    @start_time = Time.now
  end

  def build_permissions(context)
    Authorization::Permissions.new @role['permissions'], context: context
  end

  def teardown_all
    print 'Elapsed time in milliseconds: '
    puts (Time.now - @start_time) * 1000.0
    puts ''
  end
end

class TestAdminPermissions < TestAuthorizationPermissions
  ROLE = <<~JSON
    {
      "name": "admin",
      "permissions": {
        "navigate": { "any": true },
        "refund": { "any": true },
        "export_as_csv": { "any": true }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')
    permissions2 = build_permissions(['home'])

    assert permissions1.to?('navigate')
    assert permissions2.to?(['navigate'])
    assert permissions2.to?(['navigate', 'refund'])
    assert permissions1.to?('export_as_csv')

    refute permissions1.to_not?('navigate')
    refute permissions2.to_not?(['navigate'])
    refute permissions2.to_not?(['navigate', 'refund'])
    refute permissions1.to_not?(['export_as_csv'])
  end
end

module ReadOnlyRoles
  A = <<~JSON
    {
      "name": "navigateonly",
      "permissions": {
        "navigate": { "any": true }
      }
    }
  JSON

  B = <<~JSON
    {
      "name": "navigateonly2",
      "permissions": {
        "navigate": { "any": true },
        "refund": { "any": false },
        "export_as_csv": { "any": false }
      }
    }
  JSON
end

class TestReadonlyPermissions < TestAuthorizationPermissions
  def call_permissions_test
    permissions1 = build_permissions('home')
    permissions2 = build_permissions(['home'])

    assert permissions1.to?('navigate')
    assert permissions2.to?(['navigate'])
    refute permissions1.to_not?('navigate')
    refute permissions2.to_not?(['navigate'])

    refute permissions2.to?(['navigate', 'refund'])
    assert permissions2.to_not?(['navigate', 'refund'])

    refute permissions1.to?('export_as_csv')
    assert permissions1.to_not?(['export_as_csv'])
  end
end

class TestReadonlyAPermissions < TestReadonlyPermissions
  ROLE = ReadOnlyRoles::A
  alias_method :test_role_permissions, :call_permissions_test
end

class TestReadonlyBPermissions < TestReadonlyPermissions
  ROLE = ReadOnlyRoles::B
  alias_method :test_role_permissions, :call_permissions_test
end

class TestUser0Permissions < TestAuthorizationPermissions
  ROLE = <<~JSON
    {
      "name": "user0",
      "permissions": {
        "navigate": { "any": true },
        "export_as_csv": { "only": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    assert permissions1.to?('navigate')
    assert permissions1.to?(['navigate'])
    refute permissions1.to?('export_as_csv')

    permissions2 = build_permissions(['sales'])

    assert permissions2.to?(['navigate'])
    assert permissions2.to?(['navigate', 'export_as_csv'])
    assert permissions2.to?('export_as_csv')
  end
end

class TestUser1Permissions < TestAuthorizationPermissions
  ROLE = <<~JSON
    {
      "name": "user1",
      "permissions": {
        "navigate": { "only": ["sales", "commissionings", "releases"] },
        "export_as_csv": { "only": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    refute permissions1.to?('navigate')
    refute permissions1.to?('export_as_csv')

    permissions2 = build_permissions('sales')

    assert permissions2.to?('navigate')
    assert permissions2.to?('export_as_csv')
    assert permissions2.to?(['navigate', 'export_as_csv'])

    permissions3 = build_permissions('commissionings')

    assert permissions3.to?('navigate')
    refute permissions3.to?('export_as_csv')
    refute permissions3.to?(['navigate', 'export_as_csv'])

    permissions4 = build_permissions('commissionings')

    assert permissions4.to?('navigate')
    refute permissions4.to?('export_as_csv')
    refute permissions4.to?(['navigate', 'export_as_csv'])
  end
end

class TestUser2Permissions < TestAuthorizationPermissions
  ROLE = <<~JSON
    {
      "name": "user2",
      "permissions": {
        "navigate": { "only": ["sales", "commissionings", "releases"] },
        "export_as_csv": { "except": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    refute permissions1.to?('navigate')
    assert permissions1.to?('export_as_csv') # Warning!!!

    permissions2 = build_permissions('sales')

    assert permissions2.to?('navigate')
    refute permissions2.to?('export_as_csv')
    refute permissions2.to?(['navigate', 'export_as_csv'])

    permissions3 = build_permissions('commissionings')

    assert permissions3.to?('navigate')
    assert permissions3.to?('export_as_csv')
    assert permissions3.to?(['navigate', 'export_as_csv'])

    permissions4 = build_permissions('commissionings')

    assert permissions4.to?('navigate')
    assert permissions4.to?('export_as_csv')
    assert permissions4.to?(['navigate', 'export_as_csv'])
  end
end

class TestUser3Permissions < TestAuthorizationPermissions
  ROLE =  <<~JSON
    {
      "name": "user3",
      "permissions": {
        "navigate": { "except": ["sales"] },
        "export_as_csv": { "except": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    assert permissions1.to?('navigate')
    assert permissions1.to?('export_as_csv')

    permissions2 = build_permissions('sales')

    refute permissions2.to?('navigate')
    refute permissions2.to?('export_as_csv')
    refute permissions2.to?(['navigate', 'export_as_csv'])

    permissions3 = build_permissions('commissionings')

    assert permissions3.to?('navigate')
    assert permissions3.to?('export_as_csv')
    assert permissions3.to?(['navigate', 'export_as_csv'])

    permissions4 = build_permissions('commissionings')

    assert permissions4.to?('navigate')
    assert permissions4.to?('export_as_csv')
    assert permissions4.to?(['navigate', 'export_as_csv'])
  end
end

class TestAuthorizationPermissionsToHanamiClasses < TestAuthorizationPermissions
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
      "name": "hanami_classes",
      "permissions": {
        "navigate": { "any": true },
        "export_as_csv": { "except": ["sales"] }
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

    assert permissions1.to?('navigate')
    refute permissions1.to?('export_as_csv')

    view_context = extract_permissions_context_from_hanami_class(
      Dashboard::Views::Sales::Index
    )

    permissions2 = build_permissions(view_context)

    assert permissions2.to?('navigate')
    refute permissions2.to?('export_as_csv')
  end
end

class TestAuthorizationPermissionsCacheStrategy < TestAuthorizationPermissions
  ROLE = <<~JSON
    {
      "name": "cache_strategy",
      "permissions": {
        "navigate": { "any": ["true"] },
        "refund": { "except": ["sales"] }
      }
    }
  JSON

  def test_cache_with_single_feature_verification
    permissions = build_permissions(['sales'])

    assert permissions.to?('navigate')
    refute permissions.to?('refund')

    def permissions.permitted?(_feature_context); raise; end

    assert permissions.to?('navigate')
    refute permissions.to?('refund')
  end

  def test_cache_with_multiple_features_verification
    permissions = build_permissions(['sales'])

    assert permissions.to?('navigate')
    assert permissions.to_not?(['navigate', 'refund'])

    def permissions.permitted?(_feature_context); raise; end

    assert permissions.to?('navigate')
    assert permissions.to_not?(['navigate', 'refund'])
  end
end
