# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git init` command
    #
    # Create an empty Git repository or reinitialize an existing one.
    #
    # @example Typical usage
    #   init = Git::Commands::Init.new(execution_context)
    #   init.call
    #   init.call('my-repo')
    #   init.call('my-repo.git', bare: true)
    #   init.call('my-repo', initial_branch: 'main')
    #   init.call('my-repo', template: '/path/to/templates')
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-init/2.53.0
    #
    # @see https://git-scm.com/docs/git-init git-init
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Init < Git::Commands::Base
      arguments do
        literal 'init'
        flag_option %i[quiet q]
        flag_option :bare
        value_option :template, inline: true
        value_option :separate_git_dir, inline: true
        value_option :object_format, inline: true
        value_option :ref_format, inline: true
        value_option %i[initial_branch b], inline: true
        flag_or_value_option :shared, inline: true

        end_of_options
        operand :directory
      end

      # @!method call(*, **)
      #
      #   @overload call(directory = nil, **options)
      #
      #     Execute the `git init` command
      #
      #     @param directory [String, nil] path to the directory to initialize
      #
      #       If `nil` or omitted, initializes the repository in the current
      #       directory (`.`).
      #
      #       If `:bare` is false, initializes `.git` inside this directory. If
      #       `:bare` is true, creates the bare repository directly in this directory.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :quiet (false) suppress all output except errors
      #       and warnings
      #
      #       Alias: `:q`
      #
      #     @option options [Boolean] :bare (false) create a bare repository
      #
      #     @option options [String] :template (nil) path to the directory from which
      #       templates will be used
      #
      #     @option options [String] :separate_git_dir (nil) path at which to create
      #       the repository; writes a gitfile at the working-tree root pointing to it
      #
      #     @option options [String] :object_format (nil) hash algorithm for the
      #       repository (`sha1` or `sha256`)
      #
      #     @option options [String] :ref_format (nil) ref storage format for the
      #       repository (`files` or `reftable`)
      #
      #     @option options [String] :initial_branch (nil) name to use for the initial
      #       branch in the newly created repository
      #
      #       Alias: `:b`
      #
      #     @option options [Boolean, String] :shared (nil) configure the repository
      #       to be shared among multiple users
      #
      #       Pass `true` to emit `--shared` (which defaults to `group` permissions).
      #       Pass a string (e.g. `'group'`, `'all'`, `'0660'`) to emit
      #       `--shared=<permissions>`.
      #
      #     @return [Git::CommandLineResult] the result of calling `git init`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #     @api public
    end
  end
end
