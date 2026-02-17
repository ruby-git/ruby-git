# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Stash
      # Show numstat (line counts) for changes recorded in a stash entry
      #
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      # @example Show stats for the latest stash
      #   Git::Commands::Stash::ShowNumstat.new(execution_context).call
      #
      # @example Show stats for a specific stash
      #   Git::Commands::Stash::ShowNumstat.new(execution_context).call('stash@\\{2}')
      #
      # @example Show with directory statistics
      #   Git::Commands::Stash::ShowNumstat.new(execution_context).call(dirstat: true)
      #   Git::Commands::Stash::ShowNumstat.new(execution_context).call(dirstat: 'lines,cumulative')
      #
      class ShowNumstat < Base
        arguments do
          literal 'stash'
          literal 'show'
          literal '--numstat'
          literal '--shortstat'
          literal '-M'
          flag_option %i[include_untracked u], negatable: true
          flag_option :only_untracked
          flag_or_value_option :dirstat, inline: true
          operand :stash
        end

        # Show stash numstat
        #
        # @overload call(**options)
        #
        #   Show numstat for the latest stash
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :include_untracked (nil) include untracked files.
        #
        #     Alias: :u
        #
        #   @option options [Boolean] :only_untracked (nil) show only untracked files
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @overload call(stash, **options)
        #
        #   Show numstat for a specific stash
        #
        #   @param stash [String] stash reference (e.g., 'stash@\\{0}', '0')
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :include_untracked (nil) include untracked files.
        #
        #     Alias: :u
        #
        #   @option options [Boolean] :only_untracked (nil) show only untracked files
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @return [Git::CommandLineResult] the result of calling `git stash show --numstat`
        #
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
