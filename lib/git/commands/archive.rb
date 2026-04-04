# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Archive creator for files from a named tree via `git archive`
    #
    # Produces an archive of the specified format containing the tree structure
    # for the named tree, and writes it to stdout (or to a file when `out:` or
    # `output:` is given). If `prefix:` is specified it is prepended to the
    # filenames in the archive.
    #
    # @example Archive HEAD as a tar stream to a file
    #   cmd = Git::Commands::Archive.new(execution_context)
    #   File.open('release.tar', 'wb') do |f|
    #     cmd.call('HEAD', format: 'tar', out: f)
    #   end
    #
    # @example Archive a tag with a prefix
    #   cmd = Git::Commands::Archive.new(execution_context)
    #   cmd.call('v1.0', format: 'zip', prefix: 'myproject-1.0/', output: 'release.zip')
    #
    # @example Archive a subdirectory only
    #   cmd = Git::Commands::Archive.new(execution_context)
    #   cmd.call('HEAD', 'src/', format: 'tar', out: io)
    #
    # @see https://git-scm.com/docs/git-archive git-archive documentation
    #
    # @api private
    #
    class Archive < Base
      arguments do
        literal 'archive'

        # Archive format — `tar` or `zip`; user-defined formats (e.g. `tar.gz`)
        # are also supported when configured via `tar.<format>.command`
        # @see https://git-scm.com/docs/git-archive#Documentation/git-archive.txt---formatltfmtgt
        value_option :format, inline: true

        # Report progress to stderr
        # @see https://git-scm.com/docs/git-archive#Documentation/git-archive.txt---verbose
        flag_option %i[verbose v]

        # Prepend `<prefix>/` to each filename in the archive
        # @see https://git-scm.com/docs/git-archive#Documentation/git-archive.txt---prefixltprefixgt
        value_option :prefix, inline: true

        # Write the archive to `<file>` instead of stdout
        # @see https://git-scm.com/docs/git-archive#Documentation/git-archive.txt--oltfilegt
        value_option %i[output o], inline: true

        # Look for attributes in `.gitattributes` files in the working tree
        # as well as in the tree being archived
        # @see https://git-scm.com/docs/git-archive#Documentation/git-archive.txt---worktree-attributes
        flag_option :worktree_attributes

        # Instead of making an archive from the local repository, retrieve
        # a tar archive from a remote repository
        # @see https://git-scm.com/docs/git-archive#Documentation/git-archive.txt---remoteltrepogt
        value_option :remote, inline: true

        # Used with `--remote` to specify the path to `git-upload-archive`
        # on the remote side
        # @see https://git-scm.com/docs/git-archive#Documentation/git-archive.txt---execltgit-upload-archivegt
        value_option :exec, inline: true

        # Stream stdout to this IO object instead of buffering in memory
        execution_option :out

        conflicts :output, :out

        end_of_options

        # The tree or commit to produce an archive for
        operand :tree_ish, required: true

        # Limit the archive to these paths within the tree
        operand :path, repeatable: true
      end

      # Execute the `git archive` command
      #
      # Archive output is binary. On the capturing path (no `out:` option),
      # `normalize` and `chomp` are disabled so stdout bytes are returned
      # unchanged. When `out:` is given, the streaming path is used and
      # these options do not apply.
      # @!method call(*, **)
      #
      #   @overload call(tree_ish, *path, **options)
      #
      #     @param tree_ish [String] the tree or commit to produce an archive for
      #
      #     @param path [Array<String>] limit the archive to these paths
      #       within the tree
      #
      #     @param options [Hash] command options
      #
      #     @option options [String] :format (nil) archive format — `tar` or
      #       `zip`; user-defined formats are also supported
      #
      #     @option options [Boolean] :verbose (nil) report progress to stderr
      #
      #       Alias: :v
      #
      #     @option options [String] :prefix (nil) prepend `<prefix>/` to each
      #       filename in the archive
      #
      #     @option options [String] :output (nil) write the archive to
      #       this file instead of stdout
      #
      #       Alias: :o
      #
      #     @option options [Boolean] :worktree_attributes (nil) look for
      #       attributes in `.gitattributes` files in the working tree
      #
      #     @option options [String] :remote (nil) retrieve a tar archive from
      #       a remote repository instead of the local one
      #
      #     @option options [String] :exec (nil) path to `git-upload-archive`
      #       on the remote side (used with `:remote`)
      #
      #     @option options [IO, #write] :out the command output is sent to the
      #       given IO object instead of being captured in the result; the
      #       result's `.stdout` will be `''` in this case.
      #
      #     @return [Git::CommandLineResult] the result of calling
      #       `git archive`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [ArgumentError] if the tree_ish operand is missing
      #
      #     @raise [Git::FailedError] if the command returns a non-zero
      #       exit status

      # Archive output is intrinsically binary (tar, zip, etc.) — opt out of
      # Ruby string normalization and trailing-newline chomping so that
      # `result.stdout` bytes are returned unchanged. Only affects the
      # capturing path; streaming via `out:` is never normalized or chomped
      # regardless of these settings.
      #
      # @return [Boolean] `false`
      #
      def normalize_captured_stdout? = false

      # Archive output is binary, so preserve captured stdout byte-for-byte
      # even when it ends with a newline.
      #
      # @return [Boolean] `false`
      #
      def chomp_captured_stdout? = false
    end
  end
end
