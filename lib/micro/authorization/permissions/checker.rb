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
          features
            .all? { |feature| permit?(current_context, role[feature]) }
        end

        private

        def permit?(current_context, feature_permission)
          return true if feature_permission == true
          return false unless feature_permission

          if !(any = feature_permission[ANY]).nil?
            any
          elsif feature_context = feature_permission[ONLY]
            allow?(feature_context, current_context)
          elsif feature_context = feature_permission[EXCEPT]
            !allow?(feature_context, current_context)
          else
            raise NotImplementedError
          end
        end

        def allow?(feature_context, current_context)
          Utils.downcased_strings(feature_context).any? do |expectation|
            Array(expectation.split(DOT))
              .all? { |expected_value| current_context.include?(expected_value) }
          end
        end
      end

      private_constant :PermitFeature

      class BaseChecker
        attr_reader :features

        alias_method :required_features, :features

        def initialize(role, feature)
          @role = role
          @features = Utils.downcased_strings(feature)
        end

        def context?(_current_context)
          raise NotImplementedError
        end
      end

      class FeatureChecker < BaseChecker
        def context?(current_context)
          PermitFeature.call(current_context, @role, @features)
        end
      end

      class FeaturesChecker < BaseChecker
        def context?(current_context)
          @role.any? { |role| PermitFeature.call(current_context, role, @features) }
        end
      end

      private_constant :BaseChecker, :FeatureChecker, :FeaturesChecker

      module Checker
        def self.for(role, feature:)
          checker = role.is_a?(Array) ? FeaturesChecker : FeatureChecker
          checker.new(role, feature)
        end
      end
    end
  end
end
