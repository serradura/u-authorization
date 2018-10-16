# frozen_string_literal: true

class TestAuthorizationModel < Microtest::Test
  require 'ostruct'

  def setup
    @user = OpenStruct.new(id: 1)
    @role_permissions = {
      'visit' => {'any' => true},
      'export_as_csv' => {'except' => ['sales']}
    }
  end

  def test_permissions
    authorization = Authorization::Model.build(
      @user, @role_permissions,
      context: ['dashboard', 'controllers', 'sales', 'index']
    )

    assert authorization.permissions.to?('visit')
    refute authorization.permissions.to?('export_as_csv')
  end

  class FooPolicy < Authorization::Policy
    def index?
      !user.id.nil?
    end
  end

  class BarPolicy < Authorization::Policy
    def index?
      true
    end
  end

  class BazPolicy < Authorization::Policy
    def index?(value)
      value == true
    end
  end

  class NumericSubjectPolicy < Authorization::Policy
    def valid?
      subject.is_a? Numeric
    end

    def number
      subject
    end
  end

  test '#to' do
    authorization = Authorization::Model.build(@user, {}, context: [])

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

  test '#to (cache strategy)' do
    authorization = Authorization::Model.build(
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

  test '#policy (default)' do
    authorization = Authorization::Model.build(
      @user, {}, context: [], policies: { default: FooPolicy }
    )

    assert authorization.policy.class == authorization.to(:default).class
  end

  test 'same behavior to #policy and #to methods' do
    authorization = Authorization::Model.build(@user, {}, context: [],
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

  test '#with context:' do
    authorization = Authorization::Model.build(
      @user, @role_permissions,
      context: ['dashboard', 'controllers', 'sales', 'index']
    )

    new_authorization = authorization.with(context: [
      'dashboard', 'controllers', 'releases', 'index'
    ])

    refute authorization == new_authorization

    assert new_authorization.permissions.to?('visit')
    assert new_authorization.permissions.to?('export_as_csv')
  end

  test '#with policies:' do
    @user.id = nil

    authorization = Authorization::Model.build(
      @user, @role_permissions,
      context: ['sales'], policies: { default: FooPolicy }
    )

    refute authorization.policy.index?
    assert authorization.permissions.to_not?('export_as_csv')

    new_authorization = authorization.with(policies: { default: BarPolicy })

    assert new_authorization.policy.index?
    assert authorization.permissions.to_not?('export_as_csv')
  end

  test '#with context: nil, policies: nil' do
    authorization = Authorization::Model.build(
      @user, @role_permissions,
      context: ['sales'], policies: { default: FooPolicy }
    )

    authorization.with()
  rescue ArgumentError => e
    assert true
  end
end
