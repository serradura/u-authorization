# frozen_string_literal: true

class TestPermissionsModel < Microtest::Test
  require 'ostruct'

  def setup
    @user = OpenStruct.new(id: 1)
    @user_role = {
      'navigate' => {'any' => true},
      'export_as_csv' => {'except' => ['sales']}
    }
  end

  def test_feature_permissions
    permissions = Permissions::Model.build(@user, @user_role, context: [
      'dashboard', 'controllers', 'sales', 'index'
    ])

    assert permissions.features.can?('navigate')
    refute permissions.features.can?('export_as_csv')
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

    def number
      subject
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

  test '#to (cache strategy)' do
    permissions = Permissions::Model.build(@user, {}, context: [], policies: {
      bar: BarPolicy
    })

    assert permissions.to(:bar).index?

    permissions.to(:bar).class.class_eval do
      class << self
        alias_method :original_new, :new
      end

      def self.new(*args, **kargs)
        raise
      end
    end

    assert permissions.to(:bar).index?

    permissions.to(:bar).class.class_eval do
      class << self
        alias_method :new, :original_new
      end
    end
  end

  test '#policy (default)' do
    permissions = Permissions::Model.build(@user, {}, context: [], policies: {
                    default: FooPolicy
                  })

    assert permissions.policy.class == permissions.to(:default).class
  end

  test 'same behavior to #policy and #to methods' do
    permissions = Permissions::Model.build(@user, {}, context: [], policies: {
      default: FooPolicy, baz: BazPolicy, numeric_subject: NumericSubjectPolicy
    })

    assert permissions.policy(:baz).class == permissions.to(:baz).class
    assert permissions.policy(:unknow).class == permissions.to(:unknow).class

    numeric_subject_policy_a = permissions.to(:numeric_subject){ 1 }
    numeric_subject_policy_b = permissions.policy(:numeric_subject){ 1 }

    assert numeric_subject_policy_a.number == numeric_subject_policy_b.number
  end

  test '#with context:' do
    permissions = Permissions::Model.build(@user, @user_role, context: [
      'dashboard', 'controllers', 'sales', 'index'
    ])

    new_permissions = permissions.with(context: [
      'dashboard', 'controllers', 'releases', 'index'
    ])

    refute permissions == new_permissions

    assert new_permissions.features.can?('navigate')
    assert new_permissions.features.can?('export_as_csv')
  end

  test '#with policies:' do
    @user.id = nil

    permissions = Permissions::Model.build(
      @user, @user_role, context: ['sales'], policies: { default: FooPolicy }
    )

    refute permissions.policy.index?
    assert permissions.features.cannot?('export_as_csv')

    new_permissions = permissions.with(policies: { default: BarPolicy })

    assert new_permissions.policy.index?
    assert permissions.features.cannot?('export_as_csv')
  end

  test '#with context: nil, policies: nil' do
    permissions = Permissions::Model.build(
      @user, @user_role, context: ['sales'], policies: { default: FooPolicy }
    )

    new_permissions = permissions.with
  rescue ArgumentError => e
    assert true
  end
end
