# frozen_string_literal: true

module Micro
  module Authorization
    module CheckRolePermission
      extend self

      def call(context, role_permissions, required_features)
        required_features
          .all? { |feature| has_permission?(context, role_permissions[feature]) }
      end

      private

      def has_permission?(context, role_permission)
        return false if role_permission.nil?

        if role_permission == false || role_permission == true
          role_permission
        elsif !(any = role_permission['any']).nil?
          any
        elsif only = role_permission['only']
          check_feature_permission(only, context)
        elsif except = role_permission['except']
          !check_feature_permission(except, context)
        else
          raise NotImplementedError
        end
      end

      def check_feature_permission(context_values, context)
        MapValuesAsDowncasedStrings.(context_values).any? do |context_value|
            Array(context_value.split('.')).all? { |permission| context.include?(permission) }
        end
      end
    end
  end
end
