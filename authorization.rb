# frozen_string_literal: true

module Authorization
  MapValuesAsDowncasedStrings = -> (values) do
    Array(values).map { |value| String(value).downcase }
  end

  module CheckRolePermission
    extend self

    def call(context, role_permissions, required_features)
      required_features
        .all? { |feature| has_permission?(context, role_permissions[feature]) }
    end

    private

    def has_permission?(context, role_permission)
      return false if role_permission.nil?

      if !(any = role_permission['any']).nil?
        any
      elsif only = role_permission['only']
        check_feature_permission(only) { |perm| context.include?(perm) }
      elsif except = role_permission['except']
        check_feature_permission(except) { |perm| !context.include?(perm) }
      else
        raise NotImplementedError
      end
    end

    def check_feature_permission(context_values)
      MapValuesAsDowncasedStrings.(context_values).any? do |context_value|
        Array(context_value.split('.')).all? { |permission| yield(permission) }
      end
    end
  end

  class Permissions
    attr_reader :role, :context

    def self.[](instance)
      return instance if instance.is_a?(Permissions)

      raise ArgumentError, "#{instance.inspect} must be a #{self.name}"
    end

    def initialize(role_permissions, context: [])
      @role = role_permissions.dup.freeze
      @context = MapValuesAsDowncasedStrings.(context).freeze

      @cache = {}
    end

    def to?(features = nil)
      required_features = MapValuesAsDowncasedStrings.(features)

      cache_key = required_features.inspect

      return @cache[cache_key] unless @cache[cache_key].nil?

      @cache[cache_key] = CheckRolePermission.call(
        @context, @role, required_features
      )
    end

    def to_not?(features = nil)
      !to?(features)
    end
  end

  class Policy
    def self.type(klass)
      return klass if klass < self

      raise ArgumentError, "policy must be a #{self.name}"
    end

    def initialize(user, subject = nil, permissions: nil)
      @user = user
      @subject = subject
      @permissions = permissions
    end

    def method_missing(method, *args, **keyargs, &block)
      return false if method =~ /\?\z/
      super(method)
    end

    private

    def user; @user; end
    def subject; @subject; end
    def permissions; @permissions; end
  end

  class Model
    attr_reader :user, :permissions

    def self.build(user, role, context: [], policies: {})
      permissions = Permissions.new(role, context: context)

      self.new(user, permissions: permissions, policies: policies)
    end

    def initialize(user, permissions:, policies: {})
      @user = user
      @policies = {}
      @policies_cache = {}
      @permissions = Permissions[permissions]

      add_policies(policies)
    end

    def with(context: nil, policies: nil)
      if context.nil? && policies.nil?
        raise ArgumentError, 'context or policies keywords args must be defined'
      end

      new_permissions =
        Permissions.new(permissions.role, context: context || @context)

      self.class.new(
        user, permissions: new_permissions, policies: policies || @policies
      )
    end

    def add_policy(key, policy_klass)
      raise ArgumentError, 'key must be a Symbol' unless key.is_a?(Symbol)

      @policies[key] ||= Policy.type(policy_klass)

      self
    end

    def add_policies(new_policies)
      unless new_policies.is_a?(Hash)
        raise ArgumentError, "policies must be a Hash (key => #{Policy.name})"
      end

      new_policies.each &method(:add_policy)

      self
    end

    def to(policy_key)
      policy_klass = @policies.fetch(policy_key, Policy)

      return policy_klass.new(user, yield, permissions: permissions) if block_given?

      return @policies_cache[policy_key] if @policies_cache[policy_key]

      policy_klass.new(user, permissions: permissions).tap do |instance|
        @policies_cache[policy_key] = instance if policy_klass != Policy
      end
    end

    def policy(key = :default, &block)
      to(key, &block)
    end
  end
end

=begin
  class SalesPolicy < Authorization::Policy
    def edit?(record)
      user.id == record.user_id
    end
  end

  role = OpenStruct.new(
    name: 'user',
    permissions: {
      'visit' => { 'except' => ['billings'] },
      'export_as_csv' => { 'except' => ['sales'] }
    }
  )

  user = OpenStruct.new(id: 1, role: role)

  charge = OpenStruct.new(id: 2, user_id: user.id)

  authorization = Authorization::Model.build(user, user.role.permissions,
    context: ['dashboard', 'controllers', 'sales', 'index'],
    policies: { default: SalesPolicy }
  )

  authorization.permissions.to?('visit') #=> true
  authorization.permissions.to?('export_as_csv') #=> false

  authorization.policy.edit?(charge) #=> true
  authorization.to(:default).edit?(charge) #=> true

  new_authorization = authorization.with(context: [
    'dashboard', 'controllers', 'billings', 'index'
  ])

  new_authorization.permissions.to?('visit') #=> false
=end
