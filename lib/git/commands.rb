# frozen_string_literal: true

require_relative 'commands/base'
require_relative 'commands/add'
require_relative 'commands/am'
require_relative 'commands/apply'
require_relative 'commands/archive'
require_relative 'commands/branch'
require_relative 'commands/cat_file'
require_relative 'commands/checkout'
require_relative 'commands/checkout_index'
require_relative 'commands/clean'
require_relative 'commands/clone'
require_relative 'commands/commit'
require_relative 'commands/commit_tree'
require_relative 'commands/config_option_syntax'
require_relative 'commands/describe'
require_relative 'commands/diff'
require_relative 'commands/diff_files'
require_relative 'commands/diff_index'
require_relative 'commands/fetch'
require_relative 'commands/fsck'
require_relative 'commands/gc'
require_relative 'commands/grep'
require_relative 'commands/init'
require_relative 'commands/log'
require_relative 'commands/ls_files'
require_relative 'commands/ls_remote'
require_relative 'commands/ls_tree'
require_relative 'commands/merge'
require_relative 'commands/merge_base'
require_relative 'commands/mv'
require_relative 'commands/name_rev'
require_relative 'commands/pull'
require_relative 'commands/push'
require_relative 'commands/read_tree'
require_relative 'commands/remote'
require_relative 'commands/repack'
require_relative 'commands/reset'
require_relative 'commands/rev_parse'
require_relative 'commands/revert'
require_relative 'commands/rm'
require_relative 'commands/show'
require_relative 'commands/show_ref'
require_relative 'commands/stash'
require_relative 'commands/status'
require_relative 'commands/symbolic_ref'
require_relative 'commands/tag'
require_relative 'commands/update_ref'
require_relative 'commands/version'
require_relative 'commands/worktree'
require_relative 'commands/write_tree'

module Git
  # Internal command layer for the git gem
  #
  # Each git operation is represented by a class within this namespace. Command
  # classes define the CLI contract via the {Arguments} DSL, bind caller-supplied
  # parameters to command-line flags and operands, execute the subprocess through
  # {Git::CommandLine}, and return a raw {Git::CommandLineResult}.
  #
  # Commands do **not** parse output — that responsibility belongs to the
  # {Git::Parsers} layer, orchestrated by the facade ({Git::Lib} / future
  # {Git::Repository}).
  #
  # All classes in this namespace are internal (`@api private`). End users
  # should interact with the public API on {Git::Base} instead.
  #
  # ## Architecture
  #
  # ```
  # Git::Base (public API)
  #   └── Git::Lib / Git::Repository (facade — orchestrates commands + parsers)
  #         └── Git::Commands::* (defines CLI API, binds args, executes)
  #               └── Git::CommandLine (subprocess execution)
  # ```
  #
  # Simple commands inherit from {Commands::Base} and only need an `arguments`
  # block. Multi-mode git commands (e.g., `git branch`, `git stash`) are split
  # into namespace modules with one class per mode.
  #
  # @api private
  #
  # @see Git::Commands::Base
  # @see Git::Commands::Arguments
  #
  module Commands; end
end
