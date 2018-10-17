# authorization.rb

## Usage

```ruby
  require 'ostruct'
  require 'authorization'

  role = OpenStruct.new(name: 'user',
                        permissions: {
                          'visit' => { 'except' => ['billings'] },
                          'export_as_csv' => { 'except' => ['sales'] }
                        })

  user = OpenStruct.new(id: 1, role: role)

  class SalesPolicy < Authorization::Policy
    def edit?(record)
      user.id == record.user_id
    end
  end

  authorization = Authorization::Model.build(user, user.role.permissions,
    context: ['dashboard', 'controllers', 'sales', 'index'],
    policies: { default: SalesPolicy }
  )

  # Verifying the role permissions for a given context
  authorization.permissions.to?('visit')         #=> true
  authorization.permissions.to?('export_as_csv') #=> false

  charge = OpenStruct.new(id: 2, user_id: user.id)

  # The #to() method fetch and build a policy.
  authorization.to(:default).edit?(charge)
  #=> true

  # #policy() method has a similar behavior of #to(),
  # but if there is a policy named as ":default", it will be fetched and instantiated by default.
  authorization.policy.edit?(charge)
  #=> true

  # Verifying the role permissions for a custom context
  authorization.permissions.to?('visit', context: 'billings')
  #=> false

  # Cloning the authorization changing only its context.
  new_authorization = authorization.map(context: [
    'dashboard', 'controllers', 'billings', 'index'
  ])

  new_authorization.permissions.to?('visit') #=> false
```
