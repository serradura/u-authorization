# frozen_string_literal: true

require 'test_helper'

class Micro::Authorization::PolicyTest < Minitest::Test
  require 'ostruct'

  def setup
    @user = OpenStruct.new(name: 'User', id: 1)
    @record_a = OpenStruct.new(user_id: @user.id)
    @record_b = OpenStruct.new(user_id: 2)
  end

  def test_false_as_the_default_result_to_any_kind_of_query
    user = {}
    record = {}
    policy = Micro::Authorization::Policy.new(user)

    refute policy.index?
    refute policy.show?(record)
    refute policy.show?(record: record)
    refute policy.show? { record }
  end

  def test_a_non_predicate_method
    err = assert_raises(NoMethodError) { Micro::Authorization::Policy.new({}).foo }
    assert err.message.include?('foo')
  end

  class PolicyA < Micro::Authorization::Policy
    def show?
      user.id == subject.user_id
    end
  end

  def test_policy_result_when_receives_a_subject_in_the_initializer
    policy_context = {user: @user}
    assert PolicyA.new(policy_context, @record_a).show?
    refute PolicyA.new(policy_context, @record_b).show?
  end

  class PolicyB < Micro::Authorization::Policy
    def show?(record)
      permissions.to?('visit') && current_user.id == record.user_id
    end
  end

  def test_policy_result_when_receives_the_subject_as_a_query_argument
    role = { 'visit' => { 'only' => %w[users] } }
    permissions = Micro::Authorization::Permissions.new(role, context: %w[users])
    policy_context = {user: @user}

    policy = PolicyB.new(policy_context, permissions: permissions)

    assert policy.show?(@record_a)
    refute policy.show?(@record_b)
  end

  def test_policy_type
    assert_kind_of(
      Class,
      Micro::Authorization::Policy.type(PolicyA)
    )

    # ---

    err = assert_raises(ArgumentError) { Micro::Authorization::Policy.type(Hash) }
    assert_equal('policy must be a Micro::Authorization::Policy', err.message)
  end
end
