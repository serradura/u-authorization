# frozen_string_literal: true

require 'test_helper'

class Micro::Authorization::Permissions::SingleRoleTest < Minitest::Test
  require 'json'

  ROLES = <<-JS
    {
      "user": {
        "visit": { "only": ["users"] },
        "export": { "only": ["users.reports"] },
        "manage": { "only": ["users"] }
      },
      "sale": {
        "visit": { "only": ["sales"] },
        "export": { "only": ["sales.reports"] },
        "manage": { "only": ["sales"] }
      },
      "analytic": {
        "visit": { "only": ["users", "sales"] },
        "export": { "only": ["reports"] },
        "manage": { "any": false }
      },
      "admin": {
        "visit": { "any": true },
        "export": { "any": true },
        "manage": { "any": true }
      }
  }
  JS

  private def permissions(role)
    permissions = JSON.parse(ROLES)

    Micro::Authorization::Permissions
      .new(permissions[role], context: [])
  end

  def test_user_permissions
    permissions = permissions('user')
    permissions_to_visit = permissions.to('visit')
    permissions_to_export = permissions.to('export')
    permissions_to_manage = permissions.to('manage')

    #
    # feature: visit
    #
    assert permissions_to_visit.context?(%w[users])

    refute permissions_to_visit.context?(%w[sales])
    refute permissions_to_visit.context?(%w[finances])

    #
    # feature: export
    #
    assert permissions_to_export.context?(%w[users reports])

    refute permissions_to_export.context?(%w[users])
    refute permissions_to_export.context?(%w[sales])
    refute permissions_to_export.context?(%w[sales reports])

    #
    # feature: manage
    #
    assert permissions_to_manage.context?('users')

    refute permissions_to_manage.context?('sales')
    refute permissions_to_manage.context?('finances')
  end

  def test_sale_permissions
    permissions = permissions('sale')
    permissions_to_visit = permissions.to('visit')
    permissions_to_export = permissions.to('export')
    permissions_to_manage = permissions.to('manage')

    #
    # feature: visit
    #
    assert permissions_to_visit.context?(%w[sales])
    refute permissions_to_visit.context?(%w[users])

    #
    # feature: export
    #
    assert permissions_to_export.context?(%w[sales reports])

    refute permissions_to_export.context?(%w[sales])
    refute permissions_to_export.context?(%w[users])
    refute permissions_to_export.context?(%w[users reports])

    #
    # feature: manage
    #
    assert permissions_to_manage.context?('sales')

    refute permissions_to_manage.context?('users')
  end

  def test_analytic_permissions
    permissions = permissions('analytic')
    permissions_to_visit = permissions.to('visit')
    permissions_to_export = permissions.to('export')
    permissions_to_manage = permissions.to('manage')

    #
    # feature: visit
    #
    assert permissions_to_visit.context?(%w[sales])
    assert permissions_to_visit.context?(%w[users])

    #
    # feature: export
    #
    assert permissions_to_export.context?(%w[users reports])
    assert permissions_to_export.context?(%w[sales reports])

    refute permissions_to_export.context?(%w[users])
    refute permissions_to_export.context?(%w[sales])

    #
    # feature: manage
    #
    refute permissions_to_manage.context?('sales')
    refute permissions_to_manage.context?('users')
  end

  def test_analytic_permissions
    permissions = permissions('admin')
    permissions_to_visit = permissions.to('visit')
    permissions_to_export = permissions.to('export')
    permissions_to_manage = permissions.to('manage')

    #
    # feature: visit
    #
    assert permissions_to_visit.context?(%w[sales])
    assert permissions_to_visit.context?(%w[users])

    #
    # feature: export
    #
    assert permissions_to_export.context?(%w[users reports])
    assert permissions_to_export.context?(%w[sales reports])
    assert permissions_to_export.context?(%w[users])
    assert permissions_to_export.context?(%w[sales])

    #
    # feature: manage
    #
    assert permissions_to_manage.context?('sales')
    assert permissions_to_manage.context?('users')
  end

  def test_the_features_that_will_be_checked
    user_permissions = permissions('user')

    assert_equal(['visit'], user_permissions.to('visit').features)

    assert_equal(
      user_permissions.to('visit').features,
      user_permissions.to('visit').required_features
    )
  end

  def test_checker_type
    assert_instance_of(
      Micro::Authorization::Permissions::SingleRoleChecker,
      permissions('user').to('visit')
    )
  end
end
