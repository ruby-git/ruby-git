# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/stash_info'
require 'git/parsers/stash'

module Git
  module Commands
    module Stash
      # List all stash entries
      #
      # Returns information about all stash entries in the repository.
      # Each stash entry is parsed and returned as a {Git::StashInfo} object
      # containing comprehensive metadata including SHA, branch, message,
      # author/committer details, and timestamps.
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      # @api private
      #
      # @example List all stashes
      #   stashes = Git::Commands::Stash::List.new(execution_context).call
      #   stashes.each do |s|
      #     puts "#{s.short_oid} #{s.name}: #{s.message} (#{s.author_name})"
      #   end
      #
      class List
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          literal 'stash'
          literal 'list'
          custom_option :format do |v|
            "--format=#{v}"
          end
        end.freeze

        # Creates a new List command instance
        #
        # @param execution_context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # List all stash entries
        #
        # @return [Array<Git::StashInfo>] array of stash information objects
        #
        # @raise [Git::UnexpectedResultError] if stash output cannot be parsed
        #
        def call
          stdout = @execution_context.command(*ARGS.bind(format: Git::Parsers::Stash::STASH_FORMAT)).stdout
          Git::Parsers::Stash.parse_list(stdout)
        end
      end
    end
  end
end
