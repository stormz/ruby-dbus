# frozen_string_literal: true
# copied from activesupport/core_ext from Rails, MIT license
# https://github.com/rails/rails/tree/a713fdae4eb4f7ccd34932edc61561a96b8d9f35/activesupport/lib/active_support/core_ext/module

class Module
  if RUBY_VERSION >= "2.3"
    # Marks the named method as intended to be redefined, if it exists.
    # Suppresses the Ruby method redefinition warning. Prefer
    # #_dbus_redefine_method where possible.
    def _dbus_silence_redefinition_of_method(method)
      if method_defined?(method) || private_method_defined?(method)
        # This suppresses the "method redefined" warning; the self-alias
        # looks odd, but means we don't need to generate a unique name
        alias_method method, method
      end
    end
  else
    def _dbus_silence_redefinition_of_method(method)
      if method_defined?(method) || private_method_defined?(method)
        alias_method :__rails_redefine, method
        remove_method :__rails_redefine
      end
    end
  end

  # Replaces the existing method definition, if there is one, with the passed
  # block as its body.
  def _dbus_redefine_method(method, &block)
    visibility = _dbus_method_visibility(method)
    _dbus_silence_redefinition_of_method(method)
    define_method(method, &block)
    send(visibility, method)
  end

  # Replaces the existing singleton method definition, if there is one, with
  # the passed block as its body.
  def _dbus_redefine_singleton_method(method, &block)
    singleton_class._dbus_redefine_method(method, &block)
  end

  def _dbus_method_visibility(method) # :nodoc:
    case
    when private_method_defined?(method)
      :private
    when protected_method_defined?(method)
      :protected
    else
      :public
    end
  end
end
