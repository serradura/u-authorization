# frozen_string_literal: true

require 'micro/authorization/permissions/checker'
require 'micro/authorization/permissions/model'

module Micro
  module Authorization
    module Permissions
      def self.[](instance)
        return instance if instance.is_a?(Permissions::Model)

        raise ArgumentError.new(
          "#{instance.inspect} must be a #{Permissions::Model.name}"
        )
      end

      def self.new(permissions, context: [])
        Permissions::Model.new(permissions, context)
      end
    end
  end
end
