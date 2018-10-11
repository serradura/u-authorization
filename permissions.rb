# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'u-test', '0.8.0'
end

require 'json'

class Permission
  def initialize(role, context: [])
    @role = role
    @context = map_as_strings(context)
  end

  def can?(features_arg = nil)
    features = map_as_strings(features_arg).map do |feature|
      @role[feature]
    end

    features.all? { |feature| permitted?(feature) }
  end

  def cannot?(features = nil)
    !can?(features)
  end

  private

  def permitted?(feature)
    if feature.nil?
      false
    elsif !(any = feature['any']).nil?
      any
    elsif only = feature['only']
      check_each_permission(only, -> perm { @context.include?(perm) })
    elsif except = feature['except']
      check_each_permission(except, -> perm { !@context.include?(perm) })
    else
      raise NotImplementedError
    end
  end

  def map_as_strings(values)
    Array(values).map { |value| String(value).downcase }
  end

  def check_each_permission(list, validate)
    map_as_strings(list).any? do |raw_permission|
      Array(raw_permission.split('.'))
        .all? { |permission| validate.(permission) }
    end
  end
end

class TestPermission < Microtest::Test
  def setup_all
    json_role = self.class.const_get(:ROLE).tap(&method(:puts))

    @role = JSON.parse(json_role)

    @start_time = Time.now.localtime
  end

  def build_permission(role, context)
    Permission.new role['features'], context: context
  end

  def teardown_all
    print 'Elapsed time in milliseconds: '
    puts (Time.now.localtime - @start_time) * 1000.0
    puts ''
  end
end

class TestAdminPermissions < TestPermission
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
    permission1 = build_permission(@role, 'home')
    permission2 = build_permission(@role, ['home'])

    assert permission1.can?('read')
    assert permission2.can?(['read'])
    assert permission2.can?(['read', 'save'])
    assert permission1.can?('export_as_csv')

    refute permission1.cannot?('read')
    refute permission2.cannot?(['read'])
    refute permission2.cannot?(['read', 'save'])
    refute permission1.cannot?(['export_as_csv'])
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

class TestReadonlyPermissions < TestPermission
  def call_features_test
    permission1 = build_permission(@role, 'home')
    permission2 = build_permission(@role, ['home'])

    assert permission1.can?('read')
    assert permission2.can?(['read'])
    refute permission1.cannot?('read')
    refute permission2.cannot?(['read'])

    refute permission2.can?(['read', 'save'])
    assert permission2.cannot?(['read', 'save'])

    refute permission1.can?('export_as_csv')
    assert permission1.cannot?(['export_as_csv'])
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

class TestUser0Permissions < TestPermission
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
    permission1 = build_permission(@role, 'home')

    assert permission1.can?('read')
    assert permission1.can?(['read'])
    refute permission1.can?('export_as_csv')

    permission2 = build_permission(@role, ['sales'])

    assert permission2.can?(['read'])
    assert permission2.can?(['read', 'export_as_csv'])
    assert permission2.can?('export_as_csv')
  end
end

class TestUser1Permissions < TestPermission
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
    permission1 = build_permission(@role, 'home')

    refute permission1.can?('read')
    refute permission1.can?('export_as_csv')

    permission2 = build_permission(@role, 'sales')

    assert permission2.can?('read')
    assert permission2.can?('export_as_csv')
    assert permission2.can?(['read', 'export_as_csv'])

    permission3 = build_permission(@role, 'commissionings')

    assert permission3.can?('read')
    refute permission3.can?('export_as_csv')
    refute permission3.can?(['read', 'export_as_csv'])

    permission4 = build_permission(@role, 'commissionings')

    assert permission4.can?('read')
    refute permission4.can?('export_as_csv')
    refute permission4.can?(['read', 'export_as_csv'])
  end
end

class TestUser2Permissions < TestPermission
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
    permission1 = build_permission(@role, 'home')

    refute permission1.can?('read')
    assert permission1.can?('export_as_csv') # Warning!!!

    permission2 = build_permission(@role, 'sales')

    assert permission2.can?('read')
    refute permission2.can?('export_as_csv')
    refute permission2.can?(['read', 'export_as_csv'])

    permission3 = build_permission(@role, 'commissionings')

    assert permission3.can?('read')
    assert permission3.can?('export_as_csv')
    assert permission3.can?(['read', 'export_as_csv'])

    permission4 = build_permission(@role, 'commissionings')

    assert permission4.can?('read')
    assert permission4.can?('export_as_csv')
    assert permission4.can?(['read', 'export_as_csv'])
  end
end

class TestUser3Permissions < TestPermission
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
    permission1 = build_permission(@role, 'home')

    assert permission1.can?('read')
    assert permission1.can?('export_as_csv')

    permission2 = build_permission(@role, 'sales')

    refute permission2.can?('read')
    refute permission2.can?('export_as_csv')
    refute permission2.can?(['read', 'export_as_csv'])

    permission3 = build_permission(@role, 'commissionings')

    assert permission3.can?('read')
    assert permission3.can?('export_as_csv')
    assert permission3.can?(['read', 'export_as_csv'])

    permission4 = build_permission(@role, 'commissionings')

    assert permission4.can?('read')
    assert permission4.can?('export_as_csv')
    assert permission4.can?(['read', 'export_as_csv'])
  end
end

class TestPermissionsToHanamiClasses < TestPermission
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

  def hanami_class_as_an_permission_context(klass)
    p klass.name.downcase.split('::')
  end

  def test_features
    controller_context = hanami_class_as_an_permission_context(
      Dashboard::Controllers::Sales::Index
    )

    permission1 = build_permission(@role, controller_context)

    assert permission1.can?('read')
    refute permission1.can?('export_as_csv')

    view_context = hanami_class_as_an_permission_context(
      Dashboard::Views::Sales::Index
    )

    permission2 = build_permission(@role, view_context)

    assert permission2.can?('read')
    refute permission2.can?('export_as_csv')
  end
end

Microtest.call

=begin
user = User.find(user_id)

user.role_spec = #json

permission = Permission.new(user.role_spec, context: [
  'dashboard', 'controllers', 'sales', 'index'
])

permission.can?('read')
=end
