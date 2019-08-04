# frozen_string_literal: true

module Micro::Authorization
  module Permissions
    module ForEachFeature
      extend self

      DOT = '.'.freeze
      ANY = 'any'.freeze
      ONLY = 'only'.freeze
      EXCEPT = 'except'.freeze

      def authorize?(role, inside:, to:)
        to.all? { |feature| permit?(inside, role[feature]) }
      end

      private

      def permit?(current_context, feature_permission)
        case feature_permission
        when true then true
        when false, nil then false
        else permit!(current_context, feature_permission)
        end
      end

      def permit!(current_context, feature_permission)
        result = permit(current_context, feature_permission)

        return result unless result.nil?

        raise NotImplementedError
      end

      def permit(current_context, feature_permission)
        feature_context = feature_permission[ANY]
        return feature_context unless feature_context.nil?

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
  end
end
