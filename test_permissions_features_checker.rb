# frozen_string_literal: true

class TestPermissions < Microtest::Test
  require 'json'

  def setup_all
    json = self.class.const_get(:ROLE).tap(&method(:puts))

    @role = JSON.parse(json)

    @start_time = Time.now
  end

  def build_permissions(context)
    Permissions::FeaturesChecker.new @role['features'], context: context
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
        "navigate": { "any": true },
        "refund": { "any": true },
        "export_as_csv": { "any": true }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')
    permissions2 = build_permissions(['home'])

    assert permissions1.can?('navigate')
    assert permissions2.can?(['navigate'])
    assert permissions2.can?(['navigate', 'refund'])
    assert permissions1.can?('export_as_csv')

    refute permissions1.cannot?('navigate')
    refute permissions2.cannot?(['navigate'])
    refute permissions2.cannot?(['navigate', 'refund'])
    refute permissions1.cannot?(['export_as_csv'])
  end
end

module ReadOnlyRoles
  A = <<~JSON
    {
      "role": "navigateonly",
      "features": {
        "navigate": { "any": true }
      }
    }
  JSON

  B = <<~JSON
    {
      "role": "navigateonly2",
      "features": {
        "navigate": { "any": true },
        "refund": { "any": false },
        "export_as_csv": { "any": false }
      }
    }
  JSON
end

class TestReadonlyPermissions < TestPermissions
  def call_features_test
    permissions1 = build_permissions('home')
    permissions2 = build_permissions(['home'])

    assert permissions1.can?('navigate')
    assert permissions2.can?(['navigate'])
    refute permissions1.cannot?('navigate')
    refute permissions2.cannot?(['navigate'])

    refute permissions2.can?(['navigate', 'refund'])
    assert permissions2.cannot?(['navigate', 'refund'])

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
        "navigate": { "any": true },
        "export_as_csv": { "only": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    assert permissions1.can?('navigate')
    assert permissions1.can?(['navigate'])
    refute permissions1.can?('export_as_csv')

    permissions2 = build_permissions(['sales'])

    assert permissions2.can?(['navigate'])
    assert permissions2.can?(['navigate', 'export_as_csv'])
    assert permissions2.can?('export_as_csv')
  end
end

class TestUser1Permissions < TestPermissions
  ROLE = <<~JSON
    {
      "role": "user1",
      "features": {
        "navigate": { "only": ["sales", "commissionings", "releases"] },
        "export_as_csv": { "only": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    refute permissions1.can?('navigate')
    refute permissions1.can?('export_as_csv')

    permissions2 = build_permissions('sales')

    assert permissions2.can?('navigate')
    assert permissions2.can?('export_as_csv')
    assert permissions2.can?(['navigate', 'export_as_csv'])

    permissions3 = build_permissions('commissionings')

    assert permissions3.can?('navigate')
    refute permissions3.can?('export_as_csv')
    refute permissions3.can?(['navigate', 'export_as_csv'])

    permissions4 = build_permissions('commissionings')

    assert permissions4.can?('navigate')
    refute permissions4.can?('export_as_csv')
    refute permissions4.can?(['navigate', 'export_as_csv'])
  end
end

class TestUser2Permissions < TestPermissions
  ROLE = <<~JSON
    {
      "role": "user2",
      "features": {
        "navigate": { "only": ["sales", "commissionings", "releases"] },
        "export_as_csv": { "except": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    refute permissions1.can?('navigate')
    assert permissions1.can?('export_as_csv') # Warning!!!

    permissions2 = build_permissions('sales')

    assert permissions2.can?('navigate')
    refute permissions2.can?('export_as_csv')
    refute permissions2.can?(['navigate', 'export_as_csv'])

    permissions3 = build_permissions('commissionings')

    assert permissions3.can?('navigate')
    assert permissions3.can?('export_as_csv')
    assert permissions3.can?(['navigate', 'export_as_csv'])

    permissions4 = build_permissions('commissionings')

    assert permissions4.can?('navigate')
    assert permissions4.can?('export_as_csv')
    assert permissions4.can?(['navigate', 'export_as_csv'])
  end
end

class TestUser3Permissions < TestPermissions
  ROLE =  <<~JSON
    {
      "role": "user3",
      "features": {
        "navigate": { "except": ["sales"] },
        "export_as_csv": { "except": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    assert permissions1.can?('navigate')
    assert permissions1.can?('export_as_csv')

    permissions2 = build_permissions('sales')

    refute permissions2.can?('navigate')
    refute permissions2.can?('export_as_csv')
    refute permissions2.can?(['navigate', 'export_as_csv'])

    permissions3 = build_permissions('commissionings')

    assert permissions3.can?('navigate')
    assert permissions3.can?('export_as_csv')
    assert permissions3.can?(['navigate', 'export_as_csv'])

    permissions4 = build_permissions('commissionings')

    assert permissions4.can?('navigate')
    assert permissions4.can?('export_as_csv')
    assert permissions4.can?(['navigate', 'export_as_csv'])
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

    assert permissions1.can?('navigate')
    refute permissions1.can?('export_as_csv')

    view_context = extract_permissions_context_from_hanami_class(
      Dashboard::Views::Sales::Index
    )

    permissions2 = build_permissions(view_context)

    assert permissions2.can?('navigate')
    refute permissions2.can?('export_as_csv')
  end
end

class TestPermissionsCacheStrategy < TestPermissions
  ROLE = <<~JSON
    {
      "role": "cache_strategy",
      "features": {
        "navigate": { "any": ["true"] },
        "refund": { "except": ["sales"] }
      }
    }
  JSON

  def test_cache_with_single_feature_verification
    permissions = build_permissions(['sales'])

    assert permissions.can?('navigate')
    refute permissions.can?('refund')

    def permissions.permitted?(_feature_context); raise; end

    assert permissions.can?('navigate')
    refute permissions.can?('refund')
  end

  def test_cache_with_multiple_features_verification
    permissions = build_permissions(['sales'])

    assert permissions.can?('navigate')
    assert permissions.cannot?(['navigate', 'refund'])

    def permissions.permitted?(_feature_context); raise; end

    assert permissions.can?('navigate')
    assert permissions.cannot?(['navigate', 'refund'])
  end
end
