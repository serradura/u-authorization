module Micro
  module Authorization
    module Permissions
      module CheckRole
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
          Utils.values_as_downcased_strings(context_values).any? do |context_value|
            Array(context_value.split('.')).all? { |permission| context.include?(permission) }
          end
        end
      end

      private_constant :CheckRole

      class RoleChecker
        attr_reader :required_context

        def initialize(role, required_context)
          @role, @required_context = role, required_context
        end

        def context?(_context)
          raise NotImplementedError
        end

        def required_features
          warn "[DEPRECATION] `#{self.class.name}#required_features` is deprecated.\nPlease use `#{self.class.name}#required_context` instead."
          required_context
        end
      end

      class SingleRoleChecker < RoleChecker
        def context?(context)
          CheckRole.call(context, @role, @required_context)
        end
      end

      class MultiRoleChecker < RoleChecker
        def context?(context)
          @role.any? do |role|
            CheckRole.call(context, role, @required_context)
          end
        end
      end

      private_constant :RoleChecker, :SingleRoleChecker, :MultiRoleChecker

      module Checker
        def self.of(role, required_context:)
          checker = role.is_a?(Array) ? MultiRoleChecker : SingleRoleChecker
          checker.new(
            role,
            Utils.values_as_downcased_strings(required_context)
          )
        end
      end
    end
  end
end
