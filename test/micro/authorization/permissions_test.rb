# frozen_string_literal: true

require 'test_helper'

class Micro::Authorization::PermissionsTest < Minitest::Test
  require 'json'

  def setup
    json = self.class.const_get(:ROLE)

    TestUtils.puts_heredoc(json)

    @role = JSON.parse(json)

    @start_time = Time.now
  end

  def teardown
    TestUtils.puts_elapsed_time_in_ms(@start_time)
  end

  private def build_permissions(context)
    Micro::Authorization::Permissions.new @role['permissions'], context: context
  end
end

class TestAdminPermissions < Micro::Authorization::PermissionsTest
  ROLE = <<-JSON
    {
      "name": "admin",
      "permissions": {
        "visit": true,
        "refund": { "any": true },
        "export_as_csv": { "any": true }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')
    permissions2 = build_permissions(['home'])

    assert permissions1.to?('visit')
    assert permissions2.to?(['visit'])
    assert permissions2.to?(['visit', 'refund'])
    assert permissions1.to?('export_as_csv')

    refute permissions1.to_not?('visit')
    refute permissions2.to_not?(['visit'])
    refute permissions2.to_not?(['visit', 'refund'])
    refute permissions1.to_not?(['export_as_csv'])

    assert permissions1.to('visit').context?('home')
    assert permissions2.to('visit').context?(['home'])
  end
end

module ReadOnlyRoles
  A = <<-JSON
    {
      "name": "visitonly",
      "permissions": {
        "visit": { "any": true }
      }
    }
  JSON

  B = <<-JSON
    {
      "name": "visitonly2",
      "permissions": {
        "visit": { "any": true },
        "refund": false,
        "export_as_csv": false
      }
    }
  JSON
end

class TestReadonlyPermissions < Micro::Authorization::PermissionsTest
  def call_permissions_test
    permissions1 = build_permissions('home')
    permissions2 = build_permissions(['home'])

    assert permissions1.to?('visit')
    assert permissions2.to?(['visit'])
    refute permissions1.to_not?('visit')
    refute permissions2.to_not?(['visit'])

    refute permissions2.to?(['visit', 'refund'])
    assert permissions2.to_not?(['visit', 'refund'])

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

class TestUser0Permissions < Micro::Authorization::PermissionsTest
  ROLE = <<-JSON
    {
      "name": "user0",
      "permissions": {
        "visit": { "any": true },
        "export_as_csv": { "only": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    assert permissions1.to?('visit')
    assert permissions1.to?(['visit'])
    refute permissions1.to?('export_as_csv')

    permissions_to = permissions1.to('export_as_csv')

    refute permissions_to.context?('home')

    permissions2 = build_permissions(['sales'])

    assert permissions2.to?(['visit'])
    assert permissions2.to?(['visit', 'export_as_csv'])
    assert permissions2.to?('export_as_csv')

    another_permissions_to = permissions2.to('export_as_csv')

    assert another_permissions_to.context?('sales')
  end
end

class TestUser1Permissions < Micro::Authorization::PermissionsTest
  ROLE = <<-JSON
    {
      "name": "user1",
      "permissions": {
        "visit": { "only": ["sales", "commissionings", "releases"] },
        "export_as_csv": { "only": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    refute permissions1.to?('visit')
    refute permissions1.to?('export_as_csv')

    permissions2 = build_permissions('sales')

    assert permissions2.to?('visit')
    assert permissions2.to?('export_as_csv')
    assert permissions2.to?(['visit', 'export_as_csv'])

    permissions3 = build_permissions('commissionings')

    assert permissions3.to?('visit')
    refute permissions3.to?('export_as_csv')
    refute permissions3.to?(['visit', 'export_as_csv'])

    permissions4 = build_permissions('commissionings')

    assert permissions4.to?('visit')
    refute permissions4.to?('export_as_csv')
    refute permissions4.to?(['visit', 'export_as_csv'])
  end
end

class TestUser2Permissions < Micro::Authorization::PermissionsTest
  ROLE = <<-JSON
    {
      "name": "user2",
      "permissions": {
        "visit": { "only": ["sales", "commissionings", "releases"] },
        "export_as_csv": { "except": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    refute permissions1.to?('visit')
    assert permissions1.to?('export_as_csv') # Warning!!!

    permissions2 = build_permissions('sales')

    assert permissions2.to?('visit')
    refute permissions2.to?('export_as_csv')
    refute permissions2.to?(['visit', 'export_as_csv'])

    permissions3 = build_permissions('commissionings')

    assert permissions3.to?('visit')
    assert permissions3.to?('export_as_csv')
    assert permissions3.to?(['visit', 'export_as_csv'])

    permissions4 = build_permissions('commissionings')

    assert permissions4.to?('visit')
    assert permissions4.to?('export_as_csv')
    assert permissions4.to?(['visit', 'export_as_csv'])
  end
end

class TestUser3Permissions < Micro::Authorization::PermissionsTest
  ROLE =  <<-JSON
    {
      "name": "user3",
      "permissions": {
        "visit": { "except": ["sales"] },
        "export_as_csv": { "except": ["sales"] }
      }
    }
  JSON

  def test_role_permissions
    permissions1 = build_permissions('home')

    assert permissions1.to?('visit')
    assert permissions1.to?('export_as_csv')

    permissions2 = build_permissions('sales')

    refute permissions2.to?('visit')
    refute permissions2.to?('export_as_csv')
    refute permissions2.to?(['visit', 'export_as_csv'])

    permissions3 = build_permissions('commissionings')

    assert permissions3.to?('visit')
    assert permissions3.to?('export_as_csv')
    assert permissions3.to?(['visit', 'export_as_csv'])

    permissions4 = build_permissions('commissionings')

    assert permissions4.to?('visit')
    assert permissions4.to?('export_as_csv')
    assert permissions4.to?(['visit', 'export_as_csv'])
  end
end

class TestAuthorizationPermissionsToHanamiClasses < Micro::Authorization::PermissionsTest
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

  ROLE = <<-JSON
    {
      "name": "hanami_classes",
      "permissions": {
        "visit": { "any": true },
        "export_as_csv": { "except": ["sales"] }
      }
    }
  JSON

  def extract_permissions_context_from_hanami_class(klass)
    klass.name.downcase.split('::').tap do |context|
      TestUtils.inspect_test_data { "Context: #{context.inspect}" }
    end
  end

  def test_role_permissions
    controller_context = extract_permissions_context_from_hanami_class(
      Dashboard::Controllers::Sales::Index
    )

    permissions1 = build_permissions(controller_context)

    assert permissions1.to?('visit')
    refute permissions1.to?('export_as_csv')

    view_context = extract_permissions_context_from_hanami_class(
      Dashboard::Views::Sales::Index
    )

    permissions2 = build_permissions(view_context)

    assert permissions2.to?('visit')
    refute permissions2.to?('export_as_csv')
  end
end

class TestAuthorizationPermissionsCacheStrategy < Micro::Authorization::PermissionsTest
  ROLE = <<-JSON
    {
      "name": "cache_strategy",
      "permissions": {
        "visit": { "any": ["true"] },
        "refund": { "except": ["sales"] }
      }
    }
  JSON

  def test_cache_with_single_feature_verification
    permissions = build_permissions(['sales'])

    assert permissions.to?('visit')
    refute permissions.to?('refund')

    def permissions.permitted?(_feature_context); raise; end

    assert permissions.to?('visit')
    refute permissions.to?('refund')
  end

  def test_cache_with_multiple_features_verification
    permissions = build_permissions(['sales'])

    assert permissions.to?('visit')
    assert permissions.to_not?(['visit', 'refund'])

    def permissions.permitted?(_feature_context); raise; end

    assert permissions.to?('visit')
    assert permissions.to_not?(['visit', 'refund'])
  end
end