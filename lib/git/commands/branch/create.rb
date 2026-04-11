# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Branch
      # `git branch` command for creating new branches
      #
      # This command creates a new branch head pointing to the current HEAD
      # or a specified start point.
      #
      # @example Basic branch creation
      #   create = Git::Commands::Branch::Create.new(execution_context)
      #   create.call('feature-branch')
      #
      # @example Create branch from a specific start point
      #   create = Git::Commands::Branch::Create.new(execution_context)
      #   create.call('feature-branch', 'main')
      #
      # @example Force create (reset existing branch)
      #   create = Git::Commands::Branch::Create.new(execution_context)
      #   create.call('feature-branch', 'main', force: true)
      #
      # @example Create with upstream tracking
      #   create = Git::Commands::Branch::Create.new(execution_context)
      #   create.call('feature-branch', 'origin/main', track: true)
      #
      # @example Create with inherited tracking configuration
      #   create = Git::Commands::Branch::Create.new(execution_context)
      #   create.call('feature-branch', 'origin/main', track: 'inherit')
      #
      # @see Git::Commands::Branch
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      class Create < Git::Commands::Base
        arguments do
          literal 'branch'
          flag_or_value_option %i[track t], negatable: true, inline: true
          flag_option %i[force f]
          flag_option :recurse_submodules
          flag_option %i[quiet q]
          flag_option :create_reflog, negatable: true
          end_of_options
          operand :branch_name, required: true
          operand :start_point
        end

        # @!method call(*, **)
        #
        #   @overload call(branch_name, **options)
        #
        #     Create a new branch from the current HEAD
        #
        #     @param branch_name [String] the name of the branch to create
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean, String] :track (nil)
        #       configure upstream tracking for the new branch
        #
        #       - `true`: Set up tracking using the start-point branch itself (`--track`)
        #       - `false`: Do not set up tracking even if `branch.autoSetupMerge` is set (`--no-track`)
        #       - `'direct'`: Same as `true`, explicitly use start-point as upstream (`--track=direct`)
        #       - `'inherit'`: Copy upstream configuration from start-point branch (`--track=inherit`)
        #
        #       Alias: :t
        #
        #     @option options [Boolean] :force (nil)
        #       reset the branch to start point even if it already exists
        #
        #       Without this, git branch refuses to change an existing branch.
        #
        #       Alias: :f
        #
        #     @option options [Boolean] :recurse_submodules (nil)
        #       create the branch in the superproject and all submodules
        #
        #       This is an experimental feature.
        #
        #     @option options [Boolean] :quiet (nil)
        #       suppress informational messages
        #
        #       Alias: :q
        #
        #     @option options [Boolean] :create_reflog (nil)
        #       create the branch's reflog
        #
        #       Pass `true` for `--create-reflog`, `false` for `--no-create-reflog`.
        #       Enables date-based sha1 expressions such as `branch@{yesterday}`.
        #       In non-bare repositories, reflogs are usually enabled by default
        #       via `core.logAllRefUpdates`.
        #
        #     @return [Git::CommandLineResult] the result of calling `git branch`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #   @overload call(branch_name, start_point, **options)
        #
        #     Create a new branch from the specified start point
        #
        #     @param branch_name [String] the name of the branch to create
        #
        #     @param start_point [String, nil] the commit, branch, or tag to
        #       start the new branch from
        #
        #       Can also use `<rev-A>...<rev-B>` syntax for merge base.
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean, String] :track (nil)
        #       configure upstream tracking for the new branch
        #
        #       - `true`: Set up tracking using the start-point branch itself (`--track`)
        #       - `false`: Do not set up tracking even if `branch.autoSetupMerge` is set (`--no-track`)
        #       - `'direct'`: Same as `true`, explicitly use start-point as upstream (`--track=direct`)
        #       - `'inherit'`: Copy upstream configuration from start-point branch (`--track=inherit`)
        #
        #       Alias: :t
        #
        #     @option options [Boolean] :force (nil)
        #       reset the branch to start point even if it already exists
        #
        #       Without this, git branch refuses to change an existing branch.
        #
        #       Alias: :f
        #
        #     @option options [Boolean] :recurse_submodules (nil)
        #       create the branch in the superproject and all submodules
        #
        #       This is an experimental feature.
        #
        #     @option options [Boolean] :quiet (nil)
        #       suppress informational messages
        #
        #       Alias: :q
        #
        #     @option options [Boolean] :create_reflog (nil)
        #       create the branch's reflog
        #
        #       Pass `true` for `--create-reflog`, `false` for `--no-create-reflog`.
        #       Enables date-based sha1 expressions such as `branch@{yesterday}`.
        #       In non-bare repositories, reflogs are usually enabled by default
        #       via `core.logAllRefUpdates`.
        #
        #     @return [Git::CommandLineResult] the result of calling `git branch`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
