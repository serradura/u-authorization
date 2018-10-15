# frozen_string_literal: true

module TestPermissionsPolicies
  require 'ostruct'

  class StandardBehavior < Microtest::Test
    class StardardPolicy < Permissions::Policy
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
      StardardPolicy.new({}).foo
    rescue NoMethodError => e
      assert e.message.include?('foo')
    end
  end

  class CustomBehavior < Microtest::Test
    def setup
      @user = OpenStruct.new(name: 'User', id: 1)
      @record_a = OpenStruct.new(user_id: @user.id)
      @record_b = OpenStruct.new(user_id: 2)
    end

    class CustomPolicyA < Permissions::Policy
      def show?
        user.id == subject.user_id
      end
    end

    def test_policy_result_when_receives_a_subject_in_the_initializer
      assert CustomPolicyA.new(@user, @record_a).show?
      refute CustomPolicyA.new(@user, @record_b).show?
    end

    class CustomPolicyB < Permissions::Policy
      def show?(record)
        user.id == record.user_id
      end
    end

    def test_policy_result_when_receives_the_subject_as_a_query_argument
      policy = CustomPolicyB.new(@user)

      assert policy.show?(@record_a) == true && policy.show?(@record_b) == false
    end
  end
end
