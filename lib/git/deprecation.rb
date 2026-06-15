# frozen_string_literal: true

require 'active_support/deprecation'

# The Git module provides a Ruby interface to Git version control.
module Git
  # @api private
  Deprecation = ActiveSupport::Deprecation.new('5.0.0', 'Git')
end
