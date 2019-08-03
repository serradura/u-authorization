# frozen_string_literal: true

module Micro
  module Authorization
    module Permissions
      module PermitFeature
        extend self

        DOT = '.'.freeze
        ANY = 'any'.freeze
        ONLY = 'only'.freeze
        EXCEPT = 'except'.freeze

        def call(current_context, role, features)
          features.all? { |feature| permit?(current_context, role[feature]) }
        end

        private

        def permit?(current_context, feature_permission)
          case feature_permission
          when true then true
          when false, nil then false
          else authorize!(current_context, feature_permission)
          end
        end

        def authorize!(current_context, feature_permission)
          authorize(current_context, feature_permission).tap do |result|
            raise NotImplementedError if result.nil?
          end
        end

        def authorize(current_context, feature_permission)
          any = feature_permission[ANY]
          return any unless any.nil?

          feature_context = feature_permission[ONLY]
          return allow?(current_context, feature_context) if feature_context

          feature_context = feature_permission[EXCEPT]
          !allow?(current_context, feature_context) if feature_context
        end

        def allow?(current_context, feature_context)
          Utils.downcased_strings(feature_context).any? do |expectation|
            Array(expectation.split(DOT))
              .all? { |expected_value| current_context.include?(expected_value) }
          end
        end
      end

      private_constant :PermitFeature

      class SingleRoleChecker
        attr_reader :features

        alias_method :required_features, :features

        def initialize(role, feature)
          @role = role
          @features = Utils.downcased_strings(feature)
        end

        def context?(current_context)
          PermitFeature.call(current_context, @role, @features)
        end
      end

      class MultiRoleChecker < SingleRoleChecker
        def context?(current_context)
          @role.any? { |role| PermitFeature.call(current_context, role, @features) }
        end
      end

      private_constant :SingleRoleChecker, :MultiRoleChecker

      module Checker
        def self.for(role, feature)
          checker = role.is_a?(Array) ? MultiRoleChecker : SingleRoleChecker
          checker.new(role, feature)
        end
      end
    end
  end
end
