# frozen_string_literal: true

module Micro
  module Authorization
    module Utils
      def self.downcased_strings(values)
        Array(values).map { |value| String(value).downcase }
      end
    end
  end
end
