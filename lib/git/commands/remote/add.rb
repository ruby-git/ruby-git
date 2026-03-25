# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # Implements the `git remote add` command
      #
      # Adds a new remote to the repository configuration, associating a name with a URL.
      #
      # @see Git::Commands::Remote
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      class Add < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'add'
          value_option %i[track t], repeatable: true
          value_option %i[master m]
          flag_option %i[fetch f]
          flag_option :tags, negatable: true
          value_option :mirror, inline: true

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
        #     @param name [String] The remote name to create
        #
        #     @param url [String] The remote URL to configure
        #
        #     @param options [Hash] command options
        #
        #     @option options [String, Array<String>] :track (nil) Track only the given branch or branches
        #
        #       Alias: :t
        #
        #     @option options [String] :master (nil) Set the remote HEAD symbolic ref to the given branch
        #
        #       Alias: :m
        #
        #     @option options [Boolean] :fetch (nil) Fetch the remote immediately after adding it
        #
        #       Alias: :f
        #
        #     @option options [Boolean] :tags (nil) Control whether remote tags are imported during fetches
        #
        #       Pass `true` for `--tags` or `false` for `--no-tags`.
        #
        #     @option options [String] :mirror (nil) Set mirror mode
        #
        #       Common values are `fetch` and `push`.
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote add`
        #
        #     @raise [ArgumentError] if name or url is not provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
