# frozen_string_literal: true

module Permissions
  class FeaturesChecker
    attr_reader :role, :context

    def initialize(role, context: [])
      @role = role.dup.freeze
      @cache = {}
      @context = as_an_array_of_downcased_strings(context).freeze
    end

    def can?(features = nil)
      normalized_features = as_an_array_of_downcased_strings(features)

      cache_key = normalized_features.inspect

      return @cache[cache_key] unless @cache[cache_key].nil?

      @cache[cache_key] = normalized_features.all? do |feature|
        permitted?(@role[feature])
      end
    end

    def cannot?(features = nil)
      !can?(features)
    end

    private

    def permitted?(feature_context)
      return false if feature_context.nil?

      if !(any = feature_context['any']).nil?
        any
      elsif only = feature_context['only']
        check_feature_permissions(only) { |perm| @context.include?(perm) }
      elsif except = feature_context['except']
        check_feature_permissions(except) { |perm| !@context.include?(perm) }
      else
        raise NotImplementedError
      end
    end

    def check_feature_permissions(context_values)
      as_an_array_of_downcased_strings(context_values).any? do |context_value|
        Array(context_value.split('.')).all? { |permission| yield(permission) }
      end
    end

    def as_an_array_of_downcased_strings(values)
      Array(values).map { |value| String(value).downcase }
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
  end
end

=begin
  user = User.find(user_id)

  user.role_spec = {
    'visit' => {'any' => true},
    'export_as_csv' => {'except' => ['sales']}
  }

  user_permissions = Permissions::Model.build(user, user.role_spec, context: [
    'dashboard', 'controllers', 'sales', 'index'
  ])

  user_permissions.features.can?('visit') #=> true
  user_permissions.features.can?('export_as_csv') #=> false
  user_permissions.to(:sales)
=end
