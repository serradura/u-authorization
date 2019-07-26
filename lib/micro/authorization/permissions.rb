# frozen_string_literal: true

require 'micro/authorization/permissions/checker'
require 'micro/authorization/permissions/model'

module Micro
  module Authorization
    module Permissions
      def self.[](instance)
        return instance if instance.is_a?(Permissions::Model)

        raise ArgumentError, "#{instance.inspect} must be a #{self.name}"
      end

      def self.new(role_permissions, context: [])
        Permissions::Model.new(role_permissions, context: context)
      end
    end
  end
end
