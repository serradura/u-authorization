# frozen_string_literal: true

require 'test_helper'

module Micro::Authorization
  module Permissions
    class ForEachFeatureTest < Minitest::Test
      module Features
        VISIT = 'visit'
        COMMENT = 'comment'
      end

      def test_boolean_values_to_permit_a_feature
        context = %w[users index]

        role = {
          Features::VISIT => true,
          Features::COMMENT => false
        }

        assert(ForEachFeature.authorize?(role, inside: context, to: %w[visit]))

        refute(ForEachFeature.authorize?(role, inside: context, to: %w[comment]))
        refute(ForEachFeature.authorize?(role, inside: context, to: %w[visit comment]))
      end

      def test_nil_value_to_permit_a_feature
        context = %w[users index]

        role = {}

        refute(ForEachFeature.authorize?(role, inside: context, to: %w[visit]))
        refute(ForEachFeature.authorize?(role, inside: context, to: %w[comment]))
        refute(ForEachFeature.authorize?(role, inside: context, to: %w[visit comment]))
      end

      def test_the_any_option_to_permit_a_feature
        context = %w[users index]

        role = {
          Features::VISIT => {'any' => true},
          Features::COMMENT => {'any' => false}
        }

        assert(ForEachFeature.authorize?(role, inside: context, to: %w[visit]))

        refute(ForEachFeature.authorize?(role, inside: context, to: %w[comment]))
        refute(ForEachFeature.authorize?(role, inside: context, to: %w[visit comment]))
      end

      def test_error_when_the_any_option_is_null
        context = %w[users index]

        assert_raises(NotImplementedError) do
          role = { Features::VISIT => {'any' => nil} }

          ForEachFeature.authorize?(role, inside: context, to: %w[visit])
        end
      end

      def test_the_only_option_to_permit_a_feature
        context = %w[users index]

        role = {
          Features::VISIT => {'only' => ['users']},
          Features::COMMENT => {'only' => ['users']}
        }

        assert(ForEachFeature.authorize?(role, inside: context, to: %w[visit]))
        assert(ForEachFeature.authorize?(role, inside: context, to: %w[comment]))
        assert(ForEachFeature.authorize?(role, inside: context, to: %w[visit comment]))
      end

      def test_the_only_option_to_permit_a_feature
        context = %w[users index]

        role = {
          Features::VISIT => {'except' => ['users']},
          Features::COMMENT => {'except' => ['users']}
        }

        refute(ForEachFeature.authorize?(role, inside: context, to: %w[visit]))
        refute(ForEachFeature.authorize?(role, inside: context, to: %w[comment]))
        refute(ForEachFeature.authorize?(role, inside: context, to: %w[visit comment]))
      end

      def test_error_when_is_an_invalid_option
        context = %w[users index]

        assert_raises(NotImplementedError) do
          role = { Features::VISIT => {'invalid-option' => nil} }

          ForEachFeature.authorize?(role, inside: context, to: %w[visit])
        end
      end
    end
  end
end
