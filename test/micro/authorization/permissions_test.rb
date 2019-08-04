# frozen_string_literal: true

require 'test_helper'

class Micro::Authorization::PermissionsTest < Minitest::Test
  def test_build_permissions_model
    role = {}
    context = []

    assert_instance_of(
      Micro::Authorization::Permissions::Model,
      Micro::Authorization::Permissions.new(role, context: context)
    )
  end

  def test_permissions_model_validation
    permissions_model =
      Micro::Authorization::Permissions.new({}, context: [])

    assert_equal(
      permissions_model,
      Micro::Authorization::Permissions[permissions_model]
    )

    # ---

    err = assert_raises(ArgumentError) { Micro::Authorization::Permissions[{}] }
    assert_equal('{} must be a Micro::Authorization::Permissions::Model', err.message)
  end
end
