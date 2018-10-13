# frozen_string_literal: true

class Permissions
  def initialize(role, context: [])
    @role = role
    @cache = {}
    @context = as_an_array_of_downcased_strings(context)
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

=begin
  user = User.find(user_id)

  user.role_spec = {
    'read' => {'any' => true},
    'save' => {'except' => ['sales']}
  }

  user_permissions = Permissions.new(user.role_spec, context: [
    'dashboard', 'controllers', 'sales', 'index'
  ])

  user_permissions.can?('read') #=> true
  user_permissions.can?('save') #=> false
=end
