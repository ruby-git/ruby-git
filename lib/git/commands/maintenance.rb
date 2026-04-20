# frozen_string_literal: true

require_relative 'maintenance/register'
require_relative 'maintenance/run'
require_relative 'maintenance/start'
require_relative 'maintenance/stop'
require_relative 'maintenance/unregister'

module Git
  module Commands
    # Implements `git maintenance` subcommands for repository optimization
    #
    # Split into subclasses because each subcommand has a distinct purpose
    # and option set:
    #
    # - {Maintenance::Run} — run one or more maintenance tasks
    # - {Maintenance::Start} — initialize and start background maintenance
    # - {Maintenance::Stop} — halt the background maintenance schedule
    # - {Maintenance::Register} — add repository to maintenance config
    # - {Maintenance::Unregister} — remove repository from maintenance config
    #
    # All subcommands require Git 2.30.0 or later.
    #
    # @see https://git-scm.com/docs/git-maintenance git-maintenance documentation
    #
    # @api private
    #
    module Maintenance
    end
  end
end
