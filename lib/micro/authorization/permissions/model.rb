module Micro
  module Authorization
    module Permissions
      class Model
        attr_reader :role, :context

        def initialize(role, context:)
          @role = role.dup.freeze
          @cache = {}
          @context = Utils.values_as_downcased_strings(context).freeze
        end

        def to(required_context)
          Permissions::Checker.of(@role, required_context: required_context)
        end

        def to?(required_context = nil)
          has_permission_to = to(required_context)

          cache_key = has_permission_to.required_context.inspect

          return @cache[cache_key] unless @cache[cache_key].nil?

          @cache[cache_key] = has_permission_to.context?(@context)
        end

        def to_not?(required_context = nil)
          !to?(required_context)
        end
      end
    end
  end
end
