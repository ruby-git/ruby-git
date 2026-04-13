# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module CatFile
      # Retrieves a single git object after applying working-tree filter processing
      #
      # Runs `git cat-file` with `--textconv` or `--filters`. Both modes require the
      # caller to identify the object by revision **and** path so that git can look up
      # the applicable `.gitattributes` rules:
      #
      # - **`--textconv`** — apply only the textconv filter (binary-to-text conversion
      #   defined by `diff.<driver>.textconv` in `.gitattributes`); intended for
      #   human-readable display
      # - **`--filters`** — apply the full working-tree pipeline: smudge filter, EOL
      #   conversion, and textconv; returns the content exactly as `git checkout`
      #   would write it to disk
      #
      # The object can be identified as a combined `<rev>:<path>` string passed as the
      # `rev` operand, or as a bare `<rev>` with `--path=<path>` supplied separately.
      #
      # For unfiltered object access, use {CatFile::Raw}.
      # For batch queries across multiple objects, use {CatFile::Batch}.
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-cat-file/2.53.0
      #
      # @see Git::Commands::CatFile
      #
      # @see https://git-scm.com/docs/git-cat-file git-cat-file documentation
      #
      # @api private
      #
      class Filtered < Base
        arguments do
          literal 'cat-file'

          # Apply only the textconv filter (binary-to-text conversion)
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---textconv
          flag_option :textconv

          # Apply the full working-tree filter pipeline (smudge, EOL, textconv)
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---filters
          flag_option :filters

          # Specify the path separately when the rev is passed as a bare revision.
          # When used, the `rev` operand must be a plain revision (not `<rev>:<path>`).
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---pathltpathgt
          value_option :path, inline: true

          end_of_options

          # Revision identifying the object — either a combined `<rev>:<path>` string
          # (e.g. `HEAD:README.md`) or a bare revision when `--path` is also given
          operand :rev, required: true
        end

        # @!method call(*, **)
        #
        #   Execute `git cat-file --textconv` or `git cat-file --filters`.
        #
        #   @overload call(rev, textconv: true, **options)
        #     Apply the textconv filter to a single object
        #
        #     @param rev [String] combined `<rev>:<path>` identifier (e.g. `HEAD:README.md`),
        #       or a bare revision when `path:` is also given
        #
        #     @param textconv [Boolean] enable textconv mode
        #
        #     @param options [Hash] command options
        #
        #     @option options [String] :path (nil) Path to the blob when `rev` is a bare revision
        #
        #     @return [Git::CommandLineResult] the result of calling `git cat-file`
        #
        #       Stdout contains the textconv-processed content
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if the object does not exist or the path is missing
        #
        #   @overload call(rev, filters: true, **options)
        #     Apply the full working-tree filter pipeline to a single object
        #
        #     @param rev [String] combined `<rev>:<path>` identifier (e.g. `HEAD:README.md`),
        #       or a bare revision when `path:` is also given
        #
        #     @param filters [Boolean] enable full filter pipeline mode
        #
        #     @param options [Hash] command options
        #
        #     @option options [String] :path (nil) Path to the blob when `rev` is a bare revision
        #
        #     @return [Git::CommandLineResult] the result of calling `git cat-file`
        #
        #       Stdout contains the filter-processed content
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if the object does not exist or the path is missing
      end
    end
  end
end
