# frozen_string_literal: true

module Micro::Authorization
  module Permissions
    class RoleChecker
      attr_reader :features
      alias_method :required_features, :features

      def initialize(role, feature)
        @role = role
        @features = Utils.downcased_strings(feature)
      end
    end

    class SingleRoleChecker < RoleChecker
      def context?(context)
        Permissions::ForEachFeature.authorize?(@role, inside: context, to: @features)
      end
    end

    class MultipleRolesChecker < RoleChecker
      def context?(context)
        @role.any? do |role|
          Permissions::ForEachFeature.authorize?(role, inside: context, to: @features)
        end
      end
    end

    private_constant :RoleChecker

    module Checker
      def self.for(role, feature)
        checker = role.is_a?(Array) ? MultipleRolesChecker : SingleRoleChecker
        checker.new(role, feature)
      end
    end
  end
end
