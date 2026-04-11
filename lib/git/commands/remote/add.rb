# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # `git remote add` command
      #
      # Adds a new remote to the repository, associating a name with a URL and
      # configuring how tracking branches and tags are handled.
      #
      # @example Add a remote with a name and URL
      #   add = Git::Commands::Remote::Add.new(execution_context)
      #   add.call('origin', 'https://example.com/repo.git')
      #
      # @example Add a remote and immediately fetch
      #   add = Git::Commands::Remote::Add.new(execution_context)
      #   add.call('upstream', 'https://example.com/upstream.git', fetch: true)
      #
      # @example Track a specific branch and disable tag import
      #   add = Git::Commands::Remote::Add.new(execution_context)
      #   add.call('origin', 'https://example.com/repo.git', track: 'main', tags: false)
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-remote/2.53.0
      #
      # @see Git::Commands::Remote
      #
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      #
      class Add < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'add'
          value_option %i[track t], repeatable: true  # --track=<branch> (alias: :t)
          value_option %i[master m]                   # --master=<branch> (alias: :m)
          flag_option %i[fetch f]                     # --fetch (alias: :f)
          flag_option :tags, negatable: true          # --tags / --no-tags
          value_option :mirror, inline: true          # --mirror=<mode>

          end_of_options

          operand :name, required: true
          operand :url, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(name, url, **options)
        #
        #     Execute the `git remote add` command
        #
        #     @param name [String] the remote name to create
        #
        #     @param url [String] the remote URL to configure
        #
        #     @param options [Hash] command options
        #
        #     @option options [String, Array<String>] :track (nil) track only the given branch(es) during fetch
        #
        #       Accepts a single branch name or an array; each value causes a separate `--track` flag.
        #
        #       Alias: :t
        #
        #     @option options [String] :master (nil) set the remote HEAD symbolic ref to the given branch
        #
        #       Alias: :m
        #
        #     @option options [Boolean] :fetch (nil) fetch the remote immediately after adding it
        #
        #       Alias: :f
        #
        #     @option options [Boolean] :tags (nil) control whether remote tags are imported during fetches
        #
        #       Pass `true` for `--tags` or `false` for `--no-tags`.
        #
        #     @option options [String] :mirror (nil) set mirror mode
        #
        #       Common values are `'fetch'` and `'push'`.
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote add`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
