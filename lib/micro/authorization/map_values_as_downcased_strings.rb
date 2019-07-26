# frozen_string_literal: true

module Micro
  module Authorization
    MapValuesAsDowncasedStrings = -> (values) do
      Array(values).map { |value| String(value).downcase }
    end
  end
end
