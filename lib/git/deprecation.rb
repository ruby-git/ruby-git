# frozen_string_literal: true

require 'active_support/deprecation'

# The Git module provides a Ruby interface to Git version control.
module Git
  # The deprecation instance used to emit deprecation warnings for the Git gem
  #
  # @api private
  Deprecation = ActiveSupport::Deprecation.new('6.0.0', 'Git')
end
