# frozen_string_literal: true

module Micro
  module Authorization
    module Permissions
      class Model
        attr_reader :role, :context

        def initialize(permissions, context)
          @role = permissions.dup.freeze
          @cache = {}
          @context = Utils.downcased_strings(context).freeze
        end

        def to(feature)
          Permissions::Checker.for(@role, feature: feature)
        end

        def to?(feature = nil)
          has_permission_to = to(feature)

          cache_key = has_permission_to.features.inspect

          return @cache[cache_key] unless @cache[cache_key].nil?

          @cache[cache_key] = has_permission_to.context?(@context)
        end

        def to_not?(feature = nil)
          !to?(feature)
        end
      end
    end
  end
end
