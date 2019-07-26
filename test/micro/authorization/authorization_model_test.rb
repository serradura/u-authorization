# frozen_string_literal: true

require 'test_helper'

class AuthorizationModelTest < Minitest::Test
  require 'ostruct'

  def setup
    @user = OpenStruct.new(id: 1)
    @role_permissions = {
      'visit' => {'any' => true},
      'export_as_csv' => {'except' => ['sales', 'foo']}
    }
  end

  def test_permissions
    authorization = Micro::Authorization::Model.build(
      @user, @role_permissions,
      context: ['dashboard', 'controllers', 'sales', 'index']
    )

    assert authorization.permissions.to?('visit')
    refute authorization.permissions.to?('export_as_csv')
  end

  class FooPolicy < Micro::Authorization::Policy
    def index?
      !user.id.nil?
    end
  end

  class BarPolicy < Micro::Authorization::Policy
    def index?
      true
    end
  end

  class BazPolicy < Micro::Authorization::Policy
    def index?(value)
      value == true
    end
  end

  class NumericSubjectPolicy < Micro::Authorization::Policy
    def valid?
      subject.is_a? Numeric
    end

    def number
      subject
    end
  end

  def test_to
    authorization = Micro::Authorization::Model.build(@user, {}, context: [])

    refute authorization.to(:foo).index?, "forbids if the policy wasn't added"
    refute authorization.to(:bar).index?, "forbids if the policy wasn't added"
    refute authorization.to(:baz).index?(true), "forbids if the policy wasn't added"
    refute authorization.to(:numeric_subject).valid?, "forbids if the policy wasn't added"

    authorization.add_policies(foo: FooPolicy, bar: BarPolicy, baz: BazPolicy)

    assert authorization.to(:foo).index?
    assert authorization.to(:bar).index?
    assert authorization.to(:baz).index?(true)

    authorization.add_policy(:numeric_subject, NumericSubjectPolicy)

    assert authorization.to(:numeric_subject, subject: 1).valid?
  end

  def test_to_default
    authorization = Micro::Authorization::Model.build(@user, {}, context: [])

    assert authorization.to(:foo).class == Micro::Authorization::Policy
    assert authorization.to(:bar).class == Micro::Authorization::Policy

    authorization.add_policy(:default, FooPolicy)

    assert authorization.to(:foo).class == FooPolicy
    assert authorization.to(:bar).class == FooPolicy
  end

  def test_to_cache_strategy
    authorization = Micro::Authorization::Model.build(
      @user, {}, context: [], policies: { bar: BarPolicy }
    )

    assert authorization.to(:bar).index?

    authorization.to(:bar).class.class_eval do
      class << self
        alias_method :original_new, :new
      end

      def self.new(*args, **kargs)
        raise
      end
    end

    assert authorization.to(:bar).index?

    authorization.to(:bar).class.class_eval do
      class << self
        alias_method :new, :original_new
      end
    end
  end

  def test_policy_default
    authorization1 = Micro::Authorization::Model.build(
      @user, {}, context: [], policies: { default: FooPolicy }
    )

    assert authorization1.policy.class == authorization1.to(:default).class

    authorization2 = Micro::Authorization::Model.build(
      @user, {}, context: [], policies: { default: :foo, foo: FooPolicy }
    )

    assert authorization2.policy.class == authorization2.to(:default).class
  end

  def test_to_an_policy_behaviors
    authorization = Micro::Authorization::Model.build(@user, {}, context: [],
      policies: {
        default: FooPolicy, baz: BazPolicy, numeric_subject: NumericSubjectPolicy
      }
    )

    assert authorization.policy(:baz).class == authorization.to(:baz).class
    assert authorization.policy(:unknow).class == authorization.to(:unknow).class

    numeric_subject_policy_a = authorization.to(:numeric_subject, subject: 1)
    numeric_subject_policy_b = authorization.policy(:numeric_subject, subject: 1)

    assert numeric_subject_policy_a.number == numeric_subject_policy_b.number
  end

  def test_map_context
    authorization = Micro::Authorization::Model.build(
      @user, @role_permissions,
      context: ['dashboard', 'controllers', 'sales', 'index']
    )

    new_authorization = authorization.map(context: [
      'dashboard', 'controllers', 'releases', 'index'
    ])

    refute authorization == new_authorization

    assert new_authorization.permissions.to?('visit')
    assert new_authorization.permissions.to?('export_as_csv')
  end

  def test_map_policies
    @user.id = nil

    authorization = Micro::Authorization::Model.build(
      @user, @role_permissions,
      context: ['sales'], policies: { default: FooPolicy }
    )

    refute authorization.policy.index?
    assert authorization.permissions.to_not?('export_as_csv')

    new_authorization = authorization.map(policies: { default: BarPolicy })

    assert new_authorization.policy.index?
    assert authorization.permissions.to_not?('export_as_csv')
  end

  def test_map_with_an_invalid_context
    begin
      authorization = Micro::Authorization::Model.build(
        @user, @role_permissions,
        context: ['sales'], policies: { default: FooPolicy }
      )

      authorization.map()
    rescue ArgumentError => _e
      assert true
    end
  end
end
