# frozen_string_literal: true

module Permissions
  MapValuesAsDowncasedStrings = -> (values) do
    Array(values).map { |value| String(value).downcase }.freeze
  end

  module CheckFeaturePermission
    extend self

    def call(context, role, features)
      features.all? { |feature| permitted_role_feature?(context, role[feature]) }
    end

    private

    def permitted_role_feature?(context, role_feature)
      return false if role_feature.nil?

      if !(any = role_feature['any']).nil?
        any
      elsif only = role_feature['only']
        check_feature_permissions(only) { |perm| context.include?(perm) }
      elsif except = role_feature['except']
        check_feature_permissions(except) { |perm| !context.include?(perm) }
      else
        raise NotImplementedError
      end
    end

    def check_feature_permissions(context_values)
      MapValuesAsDowncasedStrings.(context_values).any? do |context_value|
        Array(context_value.split('.')).all? { |permission| yield(permission) }
      end
    end
  end

  class FeaturesChecker
    attr_reader :role, :context

    def initialize(role, context: [])
      @role = role.dup.freeze
      @cache = {}
      @context = MapValuesAsDowncasedStrings.(context)
    end

    def can?(features = nil)
      normalized_features = MapValuesAsDowncasedStrings.(features)

      cache_key = normalized_features.inspect

      return @cache[cache_key] unless @cache[cache_key].nil?

      @cache[cache_key] = CheckFeaturePermission.call(
        @context, @role, normalized_features
      )
    end

    def cannot?(features = nil)
      !can?(features)
    end
  end

  class Policy
    def initialize(user, subject = nil, features: nil)
      @user = user
      @subject = subject
      @features = features
    end

    def method_missing(method, *args, **keyargs, &block)
      return false if method =~ /\?\z/
      super(method)
    end

    private

    def user; @user; end
    def subject; @subject; end
    def features; @features; end
  end

  class Model
    attr_reader :user, :features

    def self.build(user, role, context: [], policies: {})
      features = FeaturesChecker.new(role, context: context)

      self.new(user, features: features, policies: policies)
    end

    def initialize(user, features:, policies: {})
      @user = user
      @policies = {}

      if features.is_a?(FeaturesChecker)
        @features = features
      else
        raise ArgumentError, "features must be a #{FeaturesChecker.name}"
      end

      add_policies(policies)
    end

    def with_context(values)
      new_features = FeaturesChecker.new(features.role, context: values)

      self.class.new(user, features: new_features, policies: @policies)
    end

    def add_policy(key, policy_klass)
      raise ArgumentError, 'key must be a Symbol' unless key.is_a?(Symbol)

      unless policy_klass < Policy
        raise ArgumentError, "policy must be a #{Policy.name}"
      end

      @policies[key] ||= policy_klass

      self
    end

    def add_policies(new_policies)
      unless new_policies.is_a?(Hash)
        raise ArgumentError, 'policies must be a Hash (key => Policy)'
      end

      new_policies.each &method(:add_policy)

      self
    end

    def to(policy_name)
      policy_klass = @policies.fetch(policy_name, Policy)

      return policy_klass.new(user, features: features) unless block_given?

      policy_klass.new(user, yield, features: features)
    end

    def policy(key = :default, &block)
      to(key, &block)
    end
  end
end

=begin
  user = OpenStruct.new(id: 1, role: {
    'navigate' => { 'any' => true },
    'export_as_csv' => { 'except' => ['sales'] }
  })

  user_permissions = Permissions::Model.build(user, user.role, context: [
    'dashboard', 'controllers', 'sales', 'index'
  ])

  user_permissions.features.can?('visit') #=> true
  user_permissions.features.can?('export_as_csv') #=> false
  user_permissions.to(:sales)
=end
