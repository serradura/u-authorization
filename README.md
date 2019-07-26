# µ-authorization

Simple authorization library and role managment for Ruby.

## Prerequisites

> Ruby >= 2.2.0

## Installation

Add this line to your application's Gemfile:
```
gem 'u-authorization'
```

And then execute:
```
$ bundle
```

Or install it yourself as:
```
$ gem install u-authorization
```

## Usage

```ruby
  require 'ostruct'
  require 'authorization'

  role = OpenStruct.new(
    name: 'user',
    permissions: {
      'visit' => { 'except' => ['billings'] },
      'edit_users' => false, # Same as: 'edit_users' => { 'any' => false },
      'export_as_csv' => { 'except' => ['sales'] }
    }
  )

  user = OpenStruct.new(id: 1, role: role)

  class SalesPolicy < Micro::Authorization::Policy
    def edit?(record)
      user.id == record.user_id
    end
  end

  authorization = Micro::Authorization::Model.build(user, user.role.permissions,
    context: ['dashboard', 'controllers', 'sales', 'index'],
    policies: { default: :sales, sales: SalesPolicy }
  )

  # Verifying the permissions for the given context
  authorization.permissions.to?('visit')         #=> true
  authorization.permissions.to?('export_as_csv') #=> false

  # Verifying permission for a given feature in different contexts
  has_permission_to = authorization.permissions.to('export_as_csv')
  has_permission_to.context?('billings') #=> true
  has_permission_to.context?('sales')    #=> false

  charge = OpenStruct.new(id: 2, user_id: user.id)

  # The #to() method fetch and build a policy.
  authorization.to(:sales).edit?(charge)   #=> true

  # :default is the only permitted key to receive
  # another symbol as value (a policy reference).
  authorization.to(:default).edit?(charge) #=> true

  # #policy() method has a similar behavior of #to(),
  # but if there is a policy named as ":default", it will be fetched and instantiated by default.
  authorization.policy.edit?(charge)         #=> true
  authorization.policy(:sales).edit?(charge) #=> true


  # Cloning the authorization changing only its context.
  new_authorization = authorization.map(context: [
    'dashboard', 'controllers', 'billings', 'index'
  ])

  new_authorization.permissions.to?('visit') #=> false

  authorization == new_authorization #=> false
```
