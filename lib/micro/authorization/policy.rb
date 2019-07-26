# frozen_string_literal: true

module Micro
  module Authorization
    class Policy
      def self.type(klass)
        return klass if klass < self

        raise ArgumentError, "policy must be a #{self.name}"
      end

      def initialize(context, subject = nil, permissions: nil)
        @context = context
        @subject = subject
        @permissions = permissions
      end

      def method_missing(method, *args, **keyargs, &block)
        return false if method =~ /\?\z/
        super(method)
      end

      private

      def permissions; @permissions; end
      def context; @context; end
      def subject; @subject; end
      def user
        @user ||=
          context.is_a?(Hash) ? context[:user] || context[:current_user] : context
      end
      alias_method :current_user, :user
    end
  end
end
