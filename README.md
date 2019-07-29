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
  require 'u-authorization'

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

  authorization = Micro::Authorization::Model.build(
    permissions: user.role.permissions,
    policies: { default: :sales, sales: SalesPolicy }
    context: {
      user: user,
      to_permit: ['dashboard', 'controllers', 'sales', 'index']
    }
  )

  # Note: In the context, you can use :permissions key as an alias of :to_permit. e.g:
  # context: {
  #   user: user,
  #   permissions: ['dashboard', 'controllers', 'sales', 'index']
  # }

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

## Original implementation

https://gist.github.com/serradura/7d51b979b90609d8601d0f416a9aa373
