# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git commit-tree` command
    #
    # Creates a new commit object based on the provided tree object and emits the
    # new commit object id on stdout. The log message is provided via `-m` or `-F`
    # options; multiple instances of either are concatenated as separate paragraphs.
    #
    # @example Typical usage
    #   commit_tree = Git::Commands::CommitTree.new(execution_context)
    #   commit_tree.call('abc123', m: 'Initial commit')
    #   commit_tree.call('abc123', p: %w[parent1 parent2], m: 'Merge')
    #   commit_tree.call('abc123', m: 'Signed', gpg_sign: true)
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-commit-tree/2.53.0
    #
    # @see Git::Commands
    #
    # @see https://git-scm.com/docs/git-commit-tree git-commit-tree
    #
    # @api private
    #
    class CommitTree < Git::Commands::Base
      arguments do
        literal 'commit-tree'

        # Parent commits — each -p adds a parent object
        value_option :p, repeatable: true

        # GPG signing — -S[<keyid>] / --gpg-sign[=<keyid>] / --no-gpg-sign
        flag_or_value_option %i[gpg_sign S], negatable: true, inline: true

        # Commit log message paragraphs
        value_option :m, repeatable: true, allow_empty: true

        # Read commit log message from file(s)
        value_option :F, repeatable: true

        end_of_options

        # The tree object to create a commit from
        operand :tree, required: true
      end

      # @!method call(*, **)
      #
      #   @overload call(tree, **options)
      #
      #     Execute the `git commit-tree` command
      #
      #     @param tree [String] an existing tree object SHA
      #
      #     @param options [Hash] command options
      #
      #     @option options [String, Array<String>] :p (nil) parent commit
      #       object id(s)
      #
      #       Each value adds a `-p <parent>` flag. A commit may have zero or
      #       more parents. With exactly one parent it is an ordinary commit;
      #       with more than one it is a merge commit. Initial (root) commits
      #       have no parents.
      #
      #     @option options [Boolean, String] :gpg_sign (false) sign the
      #       commit with GPG (`--gpg-sign`)
      #
      #       Pass a key-ID string to select the signing key; pass `true` to use
      #       the committer identity. Alias: `:S`
      #
      #     @option options [Boolean] :no_gpg_sign (false) countermand commit.gpgSign
      #       configuration (`--no-gpg-sign`)
      #
      #     @option options [String, Array<String>] :m (nil) a paragraph
      #       in the commit log message
      #
      #       Can be given more than once; each message becomes its own paragraph.
      #
      #     @option options [String, Array<String>] :F (nil) read the commit
      #       log message from the given file
      #
      #       Use `"-"` to read from standard input. Can be given more than
      #       once; each file's content becomes its own paragraph.
      #
      #     @return [Git::CommandLineResult] the result of calling
      #       `git commit-tree`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [ArgumentError] if the tree operand is missing
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit
      #       status
      #
      #     @api public
    end
  end
end
