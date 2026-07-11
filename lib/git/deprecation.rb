# frozen_string_literal: true

require 'active_support/deprecation'

# The Git module provides a Ruby interface to Git version control.
module Git
  # The deprecation instance used to emit deprecation warnings for the Git gem
  #
  # @api public
  Deprecation = ActiveSupport::Deprecation.new('6.0.0', 'Git')

  if (behavior = ENV.fetch('GIT_DEPRECATION_BEHAVIOR', nil))
    behavior = behavior.strip
    allowed_behaviors = ActiveSupport::Deprecation::DEFAULT_BEHAVIORS.keys.map(&:to_s)

    unless allowed_behaviors.include?(behavior)
      raise ArgumentError,
            "Invalid GIT_DEPRECATION_BEHAVIOR=#{behavior.inspect}; " \
            "expected one of: #{allowed_behaviors.join(', ')}"
    end

    Deprecation.behavior = behavior.to_sym
  end
end
