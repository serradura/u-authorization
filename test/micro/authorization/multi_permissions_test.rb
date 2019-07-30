# frozen_string_literal: true

require 'test_helper'

class Micro::Authorization::MultiPermissionsTest < Minitest::Test
  require 'json'

  ROLES = <<-JS
    {
      "analytic": {
        "visit": { "only": ["dashboard", "reports"]},
        "export": { "only": ["reports"] }
      },
      "user": {
        "visit": { "only": ["users"] },
        "export": { "any": false }
      },
      "admin": {
        "visit": { "any": true },
        "export": { "any": true }
      }
    }
  JS

  def setup
    TestUtils.puts_heredoc(ROLES)

    @roles = JSON.parse(ROLES)

    @start_time = Time.now
  end

  def teardown
    TestUtils.puts_elapsed_time_in_ms(@start_time)
  end

  def permissions(role, context)
    Micro::Authorization::Permissions.new role, context: context
  end

  def test_multi_role_permissions
    context = ['users']

    user_permissions = permissions(@roles['user'], context)
    admin_permissions = permissions(@roles['admin'], context)
    analytic_permissions = permissions(@roles['analytic'], context)

    multi_permissions1 = permissions([@roles['user'], @roles['analytic']], context)
    multi_permissions2 = permissions([@roles['analytic'], @roles['admin']], context)

    # ---

    assert user_permissions.to?('visit')
    assert admin_permissions.to?('visit')
    refute analytic_permissions.to?(['visit'])

    refute user_permissions.to?('export')
    assert admin_permissions.to?('export')
    refute analytic_permissions.to?(['export'])

    # ---

    assert multi_permissions1.to?(['visit'])
    assert multi_permissions2.to?('visit')

    refute multi_permissions1.to?('export')
    assert multi_permissions2.to?(['export'])

    # ---

    refute user_permissions.to('visit').context?('reports')
    assert admin_permissions.to('visit').context?('reports')
    assert analytic_permissions.to('visit').context?(['reports'])

    assert multi_permissions1.to('visit').context?('reports')
    assert multi_permissions1.to('visit').context?('reports')
    assert multi_permissions1.to('visit').context?(['reports'])

    assert multi_permissions2.to('visit').context?('reports')
    assert multi_permissions2.to('visit').context?('reports')
    assert multi_permissions2.to('visit').context?(['reports'])
  end
end
