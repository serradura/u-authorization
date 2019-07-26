module Micro
  module Authorization
    module Permissions
      class Model
        attr_reader :role, :context

        def initialize(role_permissions, context:)
          @role = role_permissions.dup.freeze
          @cache = {}
          @context = MapValuesAsDowncasedStrings.(context).freeze
        end

        def to(features)
          Permissions::Checker.new(@role, features)
        end

        def to?(features = nil)
          has_permission_to = to(features)

          cache_key = has_permission_to.required_features.inspect

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
