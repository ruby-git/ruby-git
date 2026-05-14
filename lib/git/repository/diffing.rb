# frozen_string_literal: true

require 'pathname'
require 'git/commands/diff'
require 'git/diff_path_status'
require 'git/escaped_path'
require 'git/repository/shared_private'

module Git
  class Repository
    # Mixin that adds diff path-status facade methods
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Diffing
      # Option keys accepted by {#diff_path_status}
      #
      # @return [Array<Symbol>]
      #
      # @api private
      #
      DIFF_PATH_STATUS_ALLOWED_OPTS = %i[path_limiter path].freeze
      private_constant :DIFF_PATH_STATUS_ALLOWED_OPTS

      # Returns the file path status between two commits
      #
      # Compares two commits (or a commit against the index/working tree) and returns
      # a {Git::DiffPathStatus} enumerating each changed file together with its status
      # code (e.g. `"M"` for modified, `"A"` for added, `"D"` for deleted,
      # `"R100"` for a rename with 100% similarity, etc.).
      #
      # @example Get all changed files between HEAD and the previous commit
      #   repo.diff_path_status #=> #<Git::DiffPathStatus ...>
      #   repo.diff_path_status.to_h #=> { "README.md" => "M", "lib/foo.rb" => "A" }
      #
      # @example Compare two specific commits
      #   repo.diff_path_status('abc1234', 'def5678').to_h
      #
      # @example Limit the comparison to a sub-path
      #   repo.diff_path_status('HEAD~1', 'HEAD', path_limiter: 'lib/')
      #
      # @param from [String] the first commit or object to compare; defaults to
      #   `'HEAD'`
      #
      # @param to [String, nil] the second commit or object to compare; when `nil`
      #   the comparison is against the index/working tree
      #
      # @param opts [Hash] options to filter the diff
      #
      # @option opts [String, Pathname, Array<String, Pathname>, nil] :path_limiter
      #   (nil) limit the status report to the given path(s)
      #
      # @option opts [String, Pathname, Array<String, Pathname>, nil] :path
      #   (nil) **deprecated** — use `:path_limiter` instead
      #
      # @return [Git::DiffPathStatus] the name-status report for the comparison
      #
      # @raise [ArgumentError] when unsupported options are provided
      #
      # @raise [ArgumentError] when `from` or `to` starts with `"-"`
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-diff git-diff documentation
      #
      def diff_path_status(from = 'HEAD', to = nil, opts = {})
        SharedPrivate.assert_valid_opts!(DIFF_PATH_STATUS_ALLOWED_OPTS, **opts)

        path_limiter = Private.resolve_path_limiter(opts)
        pathspecs = Private.normalize_pathspecs(path_limiter, 'path limiter')
        Private.validate_ref_arguments!(from, to)

        result = Private.call_diff_command(@execution_context, from, to, pathspecs)
        Git::DiffPathStatus.new(Private.extract_name_status_from_raw(result.stdout))
      end

      # @see #diff_path_status
      alias diff_name_status diff_path_status

      # Private helpers local to {Git::Repository::Diffing}
      #
      # @api private
      #
      module Private
        module_function

        # Resolves the effective path limiter from the options hash
        #
        # When `:path_limiter` is present it is used directly and no warning is
        # emitted. When only `:path` is present a deprecation warning is emitted
        # and its value is used. Returns `nil` when neither key is present.
        #
        # @param opts [Hash] the options hash from {#diff_path_status}
        #
        # @return [String, Pathname, Array, nil] the effective path limiter
        #
        def resolve_path_limiter(opts)
          if opts.key?(:path_limiter)
            opts[:path_limiter]
          elsif opts.key?(:path)
            Git::Deprecation.warn(
              'Git::Repository#diff_path_status :path option is deprecated. Use :path_limiter instead.'
            )
            opts[:path]
          end
        end

        # Raises ArgumentError if any ref starts with a dash
        #
        # @param refs [Array<String, nil>] refs to validate
        #
        # @return [void]
        #
        # @raise [ArgumentError] when any ref starts with `"-"`
        #
        def validate_ref_arguments!(*refs)
          refs.compact.each do |arg|
            raise ArgumentError, "Invalid argument: '#{arg}'" if arg.start_with?('-')
          end
        end

        # Runs git-diff with `--raw` format options and returns the result
        #
        # @param execution_context [Git::ExecutionContext] the execution context
        #   used to run git commands
        #
        # @param from [String] first ref
        #
        # @param to [String, nil] second ref
        #
        # @param pathspecs [Array<String>, nil] path limiters
        #
        # @return [Git::CommandLineResult]
        #
        def call_diff_command(execution_context, from, to, pathspecs)
          Git::Commands::Diff.new(execution_context).call(
            *[from, to].compact,
            raw: true, numstat: true, shortstat: true,
            src_prefix: 'a/', dst_prefix: 'b/',
            path: pathspecs
          )
        end

        # Normalizes path specifications for Git commands
        #
        # @param pathspecs [String, Pathname, Array<String, Pathname>, nil]
        #   the path(s) to normalize
        #
        # @param arg_name [String] the argument name used in error messages
        #
        # @return [Array<String>, nil] the normalized paths, or `nil` if none are valid
        #
        # @raise [ArgumentError] when any path is not a `String` or `Pathname`
        #
        def normalize_pathspecs(pathspecs, arg_name)
          return nil unless pathspecs

          normalized = Array(pathspecs)
          validate_pathspec_types(normalized, arg_name)

          normalized = normalized.map(&:to_s).reject(&:empty?)
          return nil if normalized.empty?

          normalized
        end

        # Raises an error if any element of `pathspecs` is not a `String` or `Pathname`
        #
        # @param pathspecs [Array] the path elements to validate
        #
        # @param arg_name [String] the argument name used in error messages
        #
        # @return [void]
        #
        # @raise [ArgumentError] when any element is not a `String` or `Pathname`
        #
        def validate_pathspec_types(pathspecs, arg_name)
          return if pathspecs.all? { |p| p.is_a?(String) || p.is_a?(Pathname) }

          raise ArgumentError, "Invalid #{arg_name}: must be a String, Pathname, or Array of Strings/Pathnames"
        end

        # Extracts name-status data from `--raw` diff output lines
        #
        # Raw lines have the format:
        #   :old_mode new_mode old_sha new_sha status\tpath
        # or for renames/copies:
        #   :old_mode new_mode old_sha new_sha Rxx\told_path\tnew_path
        #
        # @param output [String] raw diff output
        #
        # @return [Hash{String => String}] mapping of file paths to status tokens
        #
        def extract_name_status_from_raw(output)
          output.split("\n").each_with_object({}) do |line, memo|
            next unless line.start_with?(':')

            parts = line[1..].split(/\s+/, 5)
            status_and_paths = parts[4].split("\t")
            status = status_and_paths[0]
            path = status_and_paths.length > 2 ? status_and_paths[2] : status_and_paths[1]
            memo[unescape_quoted_path(path)] = status
          end
        end

        # Unescapes a git-quoted path (e.g. `"quoted_file_\\342\\230\\240"`)
        #
        # Git quotes paths that contain non-ASCII or special characters by
        # wrapping them in double-quotes and octal-escaping each byte. This
        # method strips the surrounding quotes and delegates unescaping to
        # {Git::EscapedPath}.
        #
        # @param path [String] the path as it appears in git output
        #
        # @return [String] the unescaped path
        #
        def unescape_quoted_path(path)
          if path.start_with?('"') && path.end_with?('"')
            Git::EscapedPath.new(path[1..-2]).unescape
          else
            path
          end
        end
      end

      private_constant :Private
    end
  end
end
