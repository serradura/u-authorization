# frozen_string_literal: true

module Micro
  module Authorization
    class FeaturesPermissionChecker
      attr_reader :required_features

      def initialize(role, features)
        @role = role
        @required_features = MapValuesAsDowncasedStrings.(features)
      end

      def context?(context)
        CheckRolePermission.call(context, @role, @required_features)
      end
    end
  end
end
