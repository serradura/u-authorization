# frozen_string_literal: true

require 'test_helper'

class Micro::Authorization::Permissions::ModelTest < Minitest::Test
  def test_permissions_role
    role1 = Hash.new
    permissions1 = Micro::Authorization::Permissions::Model.new(role1, [])

    assert(permissions1.role.frozen?)
    refute_same(role1, permissions1.role)
    assert_equal(role1, permissions1.role)

    # ---
    role2 = { 'visit' => true, 'comment' => false }
    permissions2 = Micro::Authorization::Permissions::Model.new(role2, [])

    assert(permissions2.role.frozen?)
    refute_same(role2, permissions1.role)
    assert_equal(role2, permissions2.role)
  end

  def test_permissions_context
    permissions1 = Micro::Authorization::Permissions::Model.new({}, 'SALES')

    assert(permissions1.context.frozen?)
    assert_equal(['sales'], permissions1.context)

    # ---

    permissions2 = Micro::Authorization::Permissions::Model.new({}, 'FooBar')

    assert(permissions2.context.frozen?)
    assert_equal(['foobar'], permissions2.context)

    # ---

    permissions3 = Micro::Authorization::Permissions::Model.new({}, [:SALES, :IndeX])

    assert(permissions3.context.frozen?)
    assert_equal(['sales', 'index'], permissions3.context)

    # ---

    permissions4 = Micro::Authorization::Permissions::Model.new({}, ['FooBar', 'index'])

    assert(permissions4.context.frozen?)
    assert_equal(['foobar', 'index'], permissions4.context)
  end

  def test_permissions_to?
    role1 = { 'visit' => true, 'comment' => false }
    role2 = { 'visit' => true, 'comment' => true }

    #
    # role 1
    #
    permissions1 =
      Micro::Authorization::Permissions::Model.new(role1, ['sales', 'index'])

    assert permissions1.to?('visit')
    refute permissions1.to?('comment')

    assert permissions1.to?(['visit'])
    refute permissions1.to?(['comment'])

    refute permissions1.to?(['visit', 'comment'])

    #
    # role 2
    #
    permissions2 =
      Micro::Authorization::Permissions::Model.new(role2, ['sales', 'index'])

    assert permissions2.to?('visit')
    assert permissions2.to?('comment')

    assert permissions2.to?(['visit'])
    assert permissions2.to?(['comment'])

    assert permissions2.to?(['visit', 'comment'])
  end

  def test_permissions_to_not?
    role1 = { 'visit' => true, 'comment' => false }
    role2 = { 'visit' => true, 'comment' => true }

    #
    # role 1
    #
    permissions1 =
      Micro::Authorization::Permissions::Model.new(role1, ['sales', 'index'])

    refute permissions1.to_not?('visit')
    assert permissions1.to_not?('comment')

    refute permissions1.to_not?(['visit'])
    assert permissions1.to_not?(['comment'])

    assert permissions1.to_not?(['visit', 'comment'])

    #
    # role 2
    #
    permissions2 =
      Micro::Authorization::Permissions::Model.new(role2, ['sales', 'index'])

    refute permissions2.to_not?('visit')
    refute permissions2.to_not?('comment')

    refute permissions2.to_not?(['visit'])
    refute permissions2.to_not?(['comment'])

    refute permissions2.to_not?(['visit', 'comment'])
  end

  def test_permissions_to_context?
    role = {
      'visit' => { 'any' => true },
      'comment' => { 'except' => ['sales'] }
    }

    permissions =
      Micro::Authorization::Permissions::Model.new(role, ['sales', 'index'])

    # ---

    has_permission_to_visit = permissions.to('visit')

    assert has_permission_to_visit.context?('invoices')
    assert has_permission_to_visit.context?('sales')

    # ---

    has_permission_to_comment = permissions.to('comment')

    assert has_permission_to_comment.context?('invoices')
    refute has_permission_to_comment.context?('sales')
  end

  def test_cache_with_single_feature_verification
    role = {
      'visit' => { 'any' => true },
      'comment' => { 'except' => ['sales'] }
    }

    permissions =
      Micro::Authorization::Permissions::Model.new(role, ['sales', 'index'])

    assert permissions.to?('visit')
    refute permissions.to?('comment')

    def permissions.to(feature)
      Struct.new(:features).new(Array(feature))
    end

    assert permissions.to?('visit')
    refute permissions.to?('comment')
  end

  def test_cache_with_multiple_features_verification
    role = {
      'visit' => { 'any' => true },
      'comment' => { 'except' => ['sales'] }
    }

    permissions =
      Micro::Authorization::Permissions::Model.new(role, ['sales', 'index'])

    refute permissions.to?(['visit', 'comment'])

    def permissions.to(feature)
      Struct.new(:features).new(Array(feature))
    end

    refute permissions.to?(['visit', 'comment'])
  end
end
