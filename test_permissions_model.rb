# frozen_string_literal: true

class TestPermissionsModel < Microtest::Test
  require 'ostruct'

  def setup_all
    @user = OpenStruct.new(id: 1)
    @user_role ={
      'visit' => {'any' => true},
      'export_as_csv' => {'except' => ['sales']}
    }
  end

  def test_feature_permissions
    permissions = Permissions::Model.build(@user, @user_role, context: [
      'dashboard', 'controllers', 'sales', 'index'
    ])

    assert permissions.features.can?('visit')
    refute permissions.features.can?('export_as_csv')
  end

  def test_with_new_context
    permissions = Permissions::Model.build(@user, @user_role, context: [
      'dashboard', 'controllers', 'sales', 'index'
    ])

    new_permissions = permissions.with_context([
      'dashboard', 'controllers', 'releases', 'index'
    ])

    refute permissions == new_permissions

    assert new_permissions.features.can?('visit')
    assert new_permissions.features.can?('export_as_csv')
  end

  class FooPolicy < Permissions::Policy
    def index?
      !user.id.nil?
    end
  end

  class BarPolicy < Permissions::Policy
    def index?
      true
    end
  end

  class BazPolicy < Permissions::Policy
    def index?(value)
      value == true
    end
  end

  class NumericSubjectPolicy < Permissions::Policy
    def valid?
      subject.is_a? Numeric
    end
  end

  test '#to' do
    permissions = Permissions::Model.build(@user, {}, context: [])

    refute permissions.to(:foo).index?, "forbids if the policy wasn't added"
    refute permissions.to(:bar).index?, "forbids if the policy wasn't added"
    refute permissions.to(:baz).index?(true), "forbids if the policy wasn't added"
    refute permissions.to(:numeric_subject).valid?, "forbids if the policy wasn't added"

    permissions.add_policies(foo: FooPolicy, bar: BarPolicy, baz: BazPolicy)

    assert permissions.to(:foo).index?
    assert permissions.to(:bar).index?
    assert permissions.to(:baz).index?(true)

    permissions.add_policy(:numeric_subject, NumericSubjectPolicy)

    assert permissions.to(:numeric_subject){ 1 }.valid?
  end
end
