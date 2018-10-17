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

    def to?(features = nil, context: nil)
      required_features = MapValuesAsDowncasedStrings.(features)

      cache_key = required_features.inspect

      return @cache[cache_key] if @cache[cache_key].nil? && !context.nil?

      custom_context = MapValuesAsDowncasedStrings.(context) if context

      @cache[cache_key] = CheckRolePermission.call(
        (custom_context || @context), @role, required_features
      )
    end

    def to_not?(features = nil, context: nil)
      !to?(features, context: context)
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

    def map(context: nil, policies: nil)
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

    def to(policy_key, subject: nil)
      policy_klass = @policies.fetch(policy_key, Policy)

      return policy_klass.new(user, subject, permissions: permissions) if subject

      return @policies_cache[policy_key] if @policies_cache[policy_key]

      policy_klass.new(user, permissions: permissions).tap do |instance|
        @policies_cache[policy_key] = instance if policy_klass != Policy
      end
    end

    def policy(key = :default, subject: nil)
      to(key, subject: subject)
    end
  end
end
