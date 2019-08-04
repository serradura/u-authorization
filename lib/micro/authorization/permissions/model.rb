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

        def to(features)
          Permissions::Checker.for(@role, features)
        end

        def to?(features = nil)
          has_permission_to = to(features)

          cache_key = has_permission_to.features.inspect

          return @cache[cache_key] unless @cache[cache_key].nil?

          @cache[cache_key] = has_permission_to.context?(@context)
        end

        def to_not?(features = nil)
          !to?(features)
        end
      end
    end
  end
end
