# frozen_string_literal: true

require 'test_helper'

module Micro::Authorization::PolicyTest
  require 'ostruct'

  class StandardBehavior < Minitest::Test
    class StardardPolicy < Micro::Authorization::Policy
    end

    def test_false_as_the_default_result_to_any_kind_of_query
      user = {}
      record = {}
      policy = StardardPolicy.new(user)

      refute policy.index?
      refute policy.show?(record)
      refute policy.show?(record: record)
      refute policy.show? { record }
    end

    def test_non_predicate_method
      err = assert_raises(NoMethodError) { StardardPolicy.new({}).foo }
      assert err.message.include?('foo')
    end
  end

  class CustomBehavior < Minitest::Test
    def setup
      @user = OpenStruct.new(name: 'User', id: 1)
      @record_a = OpenStruct.new(user_id: @user.id)
      @record_b = OpenStruct.new(user_id: 2)
    end

    class CustomPolicyA < Micro::Authorization::Policy
      def show?
        user.id == subject.user_id
      end
    end

    def test_policy_result_when_receives_a_subject_in_the_initializer
      assert CustomPolicyA.new({user: @user}, @record_a).show?
      refute CustomPolicyA.new({user: @user}, @record_b).show?
    end

    class CustomPolicyB < Micro::Authorization::Policy
      def show?(record)
        permissions.to?('visit') && current_user.id == record.user_id
      end
    end

    def test_policy_result_when_receives_the_subject_as_a_query_argument
      permissions = Micro::Authorization::Permissions.new(
        { 'visit' => { 'only' => ['test'] } }, context: ['test']
      )

      policy = CustomPolicyB.new({user: @user}, permissions: permissions)

      assert policy.show?(@record_a) == true && policy.show?(@record_b) == false
    end
  end
end
