# frozen_string_literal: true

require 'git/config_entry_info'
require 'git/parsers/config_entry'
require 'git/commands/config_option_syntax'

module Git
  # Mixin that adds structured `git config` read and write operations
  #
  # Include or extend this module to gain the full suite of `config_*` methods.
  # The including/extending class must implement two private methods:
  #
  # - {#execution_context} — returns a `Git::ExecutionContext` used to run commands
  # - {#assert_valid_scope!} — raises `ArgumentError` if a requested scope is not
  #   valid in this context (e.g., `:local` is not valid without a repository)
  #
  # Read methods that return {Git::ConfigEntryInfo} objects merge
  # `show_scope: true, show_origin: true, null: true` into the options so that
  # every returned entry carries its full provenance. Two exceptions apply:
  # {#config_get_urlmatch} merges only `show_scope: true, null: true` because
  # git does not support `--show-origin` with `--get-urlmatch` (those entries
  # always have `origin: nil`); {#config_get_colorbool} returns a plain `String`
  # and does not use these output-format options at all.
  #
  # @example Include in a repository class
  #   class MyRepo
  #     include Git::Configuring
  #     private
  #     def execution_context = @ctx
  #     def assert_valid_scope!(**) = nil  # all scopes allowed
  #   end
  #
  # @example Extend the Git module for global/system config
  #   extend Git::Configuring
  #   def self.execution_context = Git::ExecutionContext::Global.new
  #   private_class_method :execution_context
  #   def self.assert_valid_scope!(**opts)
  #     # reject :local, :worktree, :blob when called without a repository
  #   end
  #   private_class_method :assert_valid_scope!
  #
  # @api public
  #
  module Configuring # rubocop:disable Metrics/ModuleLength
    # @!group Read Operations

    # @api private
    CONFIG_GET_ALLOWED_OPTS = %i[global system local worktree file f blob includes no_includes type default].freeze
    private_constant :CONFIG_GET_ALLOWED_OPTS

    # Retrieve a single config entry by key name
    #
    # Wraps `git config --get --show-scope --show-origin --null`.
    #
    # @example Get a single config entry
    #   entry = repo.config_get('user.name')
    #   entry&.value  # => "Alice"
    #
    # @param name [String] the full dotted config key (e.g. `"user.name"`)
    #
    # @param value_regex [String, nil] optional regex to filter by value
    #
    # @param options [Hash] scope and filter options forwarded to the command
    #
    # @option options [Boolean, nil] :global (nil) read from `~/.gitconfig`
    #
    # @option options [Boolean, nil] :system (nil) read from the system config file
    #
    # @option options [Boolean, nil] :local (nil) read from `.git/config`
    #
    # @option options [Boolean, nil] :worktree (nil) read from the worktree config
    #
    # @option options [String, nil] :file (nil) path to a custom config file (alias: `:f`)
    #
    # @option options [String, nil] :blob (nil) read from a git blob object
    #
    # @option options [Boolean, nil] :includes (nil) follow include directives
    #
    # @option options [Boolean, nil] :no_includes (nil) suppress include directives
    #
    # @option options [String, nil] :type (nil) enforce a type constraint on the value
    #
    # @option options [String, nil] :default (nil) value to return when the key is missing
    #
    # @return [Git::ConfigEntryInfo, nil] the matching entry, or `nil` when not found
    #
    # @raise [ArgumentError] if unsupported options are provided
    #
    # @raise [Git::FailedError] if git exits with an unexpected non-zero status
    #
    def config_get(name, value_regex = nil, **options)
      Private.assert_valid_opts!(CONFIG_GET_ALLOWED_OPTS, **options)
      assert_valid_scope!(**options)
      options = options.merge(show_scope: true, show_origin: true, null: true)
      cmd = Git::Commands::ConfigOptionSyntax::Get.new(execution_context)
      output = cmd.call(name, value_regex, **options).stdout
      Git::Parsers::ConfigEntry.parse_get(name, output)
    end

    # @api private
    CONFIG_GET_ALL_ALLOWED_OPTS = %i[global system local worktree file f blob includes no_includes type].freeze
    private_constant :CONFIG_GET_ALL_ALLOWED_OPTS

    # Retrieve all values for a multi-valued config key
    #
    # Wraps `git config --get-all --show-scope --show-origin --null`.
    #
    # @example Get all values for a multi-valued key
    #   entries = repo.config_get_all('remote.origin.url')
    #   entries.map(&:value)  # => ["https://...", "git@..."]
    #
    # @param name [String] the full dotted config key
    #
    # @param value_regex [String, nil] optional regex to filter by value
    #
    # @param options [Hash] scope and filter options
    #
    # @option options [Boolean, nil] :global (nil) read from `~/.gitconfig`
    #
    # @option options [Boolean, nil] :system (nil) read from the system config file
    #
    # @option options [Boolean, nil] :local (nil) read from `.git/config`
    #
    # @option options [Boolean, nil] :worktree (nil) read from the worktree config
    #
    # @option options [String, nil] :file (nil) path to a custom config file (alias: `:f`)
    #
    # @option options [String, nil] :blob (nil) read from a git blob object
    #
    # @option options [Boolean, nil] :includes (nil) follow include directives
    #
    # @option options [Boolean, nil] :no_includes (nil) suppress include directives
    #
    # @option options [String, nil] :type (nil) enforce a type constraint on the value
    #
    # @return [Array<Git::ConfigEntryInfo>] all entries matching the key
    #
    # @raise [ArgumentError] if unsupported options are provided
    #
    # @raise [Git::FailedError] if git exits with an unexpected non-zero status
    #
    def config_get_all(name, value_regex = nil, **options)
      Private.assert_valid_opts!(CONFIG_GET_ALL_ALLOWED_OPTS, **options)
      assert_valid_scope!(**options)
      options = options.merge(show_scope: true, show_origin: true, null: true)
      cmd = Git::Commands::ConfigOptionSyntax::GetAll.new(execution_context)
      output = cmd.call(name, value_regex, **options).stdout
      Git::Parsers::ConfigEntry.parse_get_all(name, output)
    end

    # @api private
    CONFIG_GET_COLORBOOL_ALLOWED_OPTS = %i[global system local worktree file f blob includes no_includes].freeze
    private_constant :CONFIG_GET_COLORBOOL_ALLOWED_OPTS

    # @overload config_get_colorbool(name, stdout_is_tty = nil, **options)
    #
    #   Query whether color output is enabled for a given config slot
    #
    #   Wraps `git config --get-colorbool`.
    #
    #   @example Check color status for color.ui
    #     repo.config_get_colorbool('color.ui')  # => "true"
    #
    #   @param name [String] the config key to check (e.g. `"color.ui"`)
    #
    #   @param stdout_is_tty [Boolean, nil] whether stdout is a TTY
    #
    #   @param options [Hash] scope and filter options
    #
    #   @option options [Boolean, nil] :global (nil) read from `~/.gitconfig`
    #
    #   @option options [Boolean, nil] :system (nil) read from the system config file
    #
    #   @option options [Boolean, nil] :local (nil) read from `.git/config`
    #
    #   @option options [Boolean, nil] :worktree (nil) read from the worktree config
    #
    #   @option options [String, nil] :file (nil) path to a custom config file (alias: `:f`)
    #
    #   @option options [String, nil] :blob (nil) read from a git blob object
    #
    #   @option options [Boolean, nil] :includes (nil) follow include directives (`--includes`)
    #
    #   @option options [Boolean, nil] :no_includes (nil) suppress include directives (`--no-includes`)
    #
    #   @return [String] `"true"` or `"false"`
    #
    #   @raise [ArgumentError] if unsupported options are provided
    #
    #   @raise [Git::FailedError] if git exits with an unexpected non-zero status
    #
    def config_get_colorbool(name, stdout_is_tty = nil, **)
      Private.assert_valid_opts!(CONFIG_GET_COLORBOOL_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::GetColorBool.new(execution_context)
      cmd.call(name, stdout_is_tty, **).stdout.chomp
    end

    # @api private
    CONFIG_GET_REGEXP_ALLOWED_OPTS = %i[global system local worktree file f blob includes no_includes type].freeze
    private_constant :CONFIG_GET_REGEXP_ALLOWED_OPTS

    # Retrieve all config entries whose key matches a regular expression
    #
    # Wraps `git config --get-regexp --show-scope --show-origin --null`.
    #
    # @example Get all remote-related config entries
    #   entries = repo.config_get_regexp('remote\\.')
    #   entries.map(&:key)  # => ["remote.origin.url", ...]
    #
    # @param name_regex [String] regex matched against config key names
    #
    # @param value_regex [String, nil] optional regex to filter by value
    #
    # @param options [Hash] scope and filter options
    #
    # @option options [Boolean, nil] :global (nil) read from `~/.gitconfig`
    #
    # @option options [Boolean, nil] :system (nil) read from the system config file
    #
    # @option options [Boolean, nil] :local (nil) read from `.git/config`
    #
    # @option options [Boolean, nil] :worktree (nil) read from the worktree config
    #
    # @option options [String, nil] :file (nil) path to a custom config file (alias: `:f`)
    #
    # @option options [String, nil] :blob (nil) read from a git blob object
    #
    # @option options [Boolean, nil] :includes (nil) follow include directives
    #
    # @option options [Boolean, nil] :no_includes (nil) suppress include directives
    #
    # @option options [String, nil] :type (nil) enforce a type constraint on the value
    #
    # @return [Array<Git::ConfigEntryInfo>] all entries whose key matches the regex
    #
    # @raise [ArgumentError] if unsupported options are provided
    #
    # @raise [Git::FailedError] if git exits with an unexpected non-zero status
    #
    def config_get_regexp(name_regex, value_regex = nil, **options)
      Private.assert_valid_opts!(CONFIG_GET_REGEXP_ALLOWED_OPTS, **options)
      assert_valid_scope!(**options)
      options = options.merge(show_scope: true, show_origin: true, null: true)
      cmd = Git::Commands::ConfigOptionSyntax::GetRegexp.new(execution_context)
      output = cmd.call(name_regex, value_regex, **options).stdout
      Git::Parsers::ConfigEntry.parse_list(output)
    end

    # @api private
    CONFIG_GET_URLMATCH_ALLOWED_OPTS = %i[global system local worktree file f blob includes no_includes type].freeze
    private_constant :CONFIG_GET_URLMATCH_ALLOWED_OPTS

    # Retrieve config entries whose URL pattern matches a given URL
    #
    # Wraps `git config --get-urlmatch --show-scope --null`.
    #
    # @example Get config entries for a specific URL
    #   entries = repo.config_get_urlmatch('http', 'https://github.com/user/repo')
    #   entries.map(&:key)
    #
    # @param name [String] the config section or key prefix to look up
    #
    # @param url [String] the URL to match against
    #
    # @param options [Hash] scope and filter options
    #
    # @option options [Boolean, nil] :global (nil) read from `~/.gitconfig`
    #
    # @option options [Boolean, nil] :system (nil) read from the system config file
    #
    # @option options [Boolean, nil] :local (nil) read from `.git/config`
    #
    # @option options [Boolean, nil] :worktree (nil) read from the worktree config
    #
    # @option options [String, nil] :file (nil) path to a custom config file (alias: `:f`)
    #
    # @option options [String, nil] :blob (nil) read from a git blob object
    #
    # @option options [Boolean, nil] :includes (nil) follow include directives
    #
    # @option options [Boolean, nil] :no_includes (nil) suppress include directives
    #
    # @option options [String, nil] :type (nil) enforce a type constraint on the value
    #
    # @return [Array<Git::ConfigEntryInfo>] all entries matching the URL; `origin` is `nil` on each
    #
    # @raise [ArgumentError] if unsupported options are provided
    #
    # @raise [Git::FailedError] if git exits with an unexpected non-zero status
    #
    # @note `--show-origin` is not supported by git for `--get-urlmatch`, so the
    #   {Git::ConfigEntryInfo} entries returned by this method always have
    #   `origin: nil`.
    #
    def config_get_urlmatch(name, url, **options)
      Private.assert_valid_opts!(CONFIG_GET_URLMATCH_ALLOWED_OPTS, **options)
      assert_valid_scope!(**options)
      options = options.merge(show_scope: true, null: true)
      cmd = Git::Commands::ConfigOptionSyntax::GetUrlmatch.new(execution_context)
      output = cmd.call(name, url, **options).stdout
      Git::Parsers::ConfigEntry.parse_urlmatch(output)
    end

    # @api private
    CONFIG_LIST_ALLOWED_OPTS = %i[global system local worktree file f blob includes no_includes type].freeze
    private_constant :CONFIG_LIST_ALLOWED_OPTS

    # List all visible config entries
    #
    # Wraps `git config --list --show-scope --show-origin --null`.
    #
    # @example List all config entries
    #   entries = repo.config_list
    #   entries.first.scope  # => "local"
    #
    # @param options [Hash] scope and filter options
    #
    # @option options [Boolean, nil] :global (nil) read from `~/.gitconfig`
    #
    # @option options [Boolean, nil] :system (nil) read from the system config file
    #
    # @option options [Boolean, nil] :local (nil) read from `.git/config`
    #
    # @option options [Boolean, nil] :worktree (nil) read from the worktree config
    #
    # @option options [String, nil] :file (nil) path to a custom config file (alias: `:f`)
    #
    # @option options [String, nil] :blob (nil) read from a git blob object
    #
    # @option options [Boolean, nil] :includes (nil) follow include directives
    #
    # @option options [Boolean, nil] :no_includes (nil) suppress include directives
    #
    # @option options [String, nil] :type (nil) enforce a type constraint on the value
    #
    # @return [Array<Git::ConfigEntryInfo>] all visible config entries
    #
    # @raise [ArgumentError] if unsupported options are provided
    #
    # @raise [Git::FailedError] if git exits with an unexpected non-zero status
    #
    def config_list(**options)
      Private.assert_valid_opts!(CONFIG_LIST_ALLOWED_OPTS, **options)
      assert_valid_scope!(**options)
      options = options.merge(show_scope: true, show_origin: true, null: true)
      cmd = Git::Commands::ConfigOptionSyntax::List.new(execution_context)
      output = cmd.call(**options).stdout
      Git::Parsers::ConfigEntry.parse_list(output)
    end

    # @!endgroup

    # @!group Write Operations

    # @api private
    CONFIG_ADD_ALLOWED_OPTS = %i[global system local worktree file f blob type].freeze
    private_constant :CONFIG_ADD_ALLOWED_OPTS

    # @overload config_add(name, value, **options)
    #
    #   Append a value to a multi-valued config key
    #
    #   Wraps `git config --add`.
    #
    #   @example Append a URL to a multi-valued remote key
    #     repo.config_add('remote.origin.url', 'git@github.com:user/repo.git')
    #
    #   @param name [String] the full dotted config key
    #
    #   @param value [String] the value to append
    #
    #   @param options [Hash] scope options
    #
    #   @option options [Boolean, nil] :global (nil) write to `~/.gitconfig`
    #
    #   @option options [Boolean, nil] :system (nil) write to the system config file
    #
    #   @option options [Boolean, nil] :local (nil) write to `.git/config`
    #
    #   @option options [Boolean, nil] :worktree (nil) write to the worktree config
    #
    #   @option options [String, nil] :file (nil) path to a custom config file (alias: `:f`)
    #
    #   @option options [String, nil] :blob (nil) write to a git blob object
    #
    #   @option options [String, nil] :type (nil) coerce the value to the given type (e.g. `"bool"`, `"int"`)
    #
    #   @return [nil]
    #
    #   @raise [ArgumentError] if unsupported options are provided
    #
    #   @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def config_add(name, value, **)
      Private.assert_valid_opts!(CONFIG_ADD_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::Add.new(execution_context)
      cmd.call(name, value, **)
      nil
    end

    # @api private
    CONFIG_REMOVE_SECTION_ALLOWED_OPTS = %i[global system local worktree file f blob].freeze
    private_constant :CONFIG_REMOVE_SECTION_ALLOWED_OPTS

    # @overload config_remove_section(name, **options)
    #
    #   Remove an entire config section
    #
    #   Wraps `git config --remove-section`.
    #
    #   @example Remove the origin remote section
    #     repo.config_remove_section('remote.origin')
    #
    #   @param name [String] the section name to remove (e.g. `"remote.origin"`)
    #
    #   @param options [Hash] scope options
    #
    #   @option options [Boolean, nil] :global (nil) remove from `~/.gitconfig`
    #
    #   @option options [Boolean, nil] :system (nil) remove from the system config file
    #
    #   @option options [Boolean, nil] :local (nil) remove from `.git/config`
    #
    #   @option options [Boolean, nil] :worktree (nil) remove from the worktree config
    #
    #   @option options [String, nil] :file (nil) path to a custom config file (alias: `:f`)
    #
    #   @option options [String, nil] :blob (nil) remove from a git blob object
    #
    #   @return [nil]
    #
    #   @raise [ArgumentError] if unsupported options are provided
    #
    #   @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def config_remove_section(name, **)
      Private.assert_valid_opts!(CONFIG_REMOVE_SECTION_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::RemoveSection.new(execution_context)
      cmd.call(name, **)
      nil
    end

    # @api private
    CONFIG_RENAME_SECTION_ALLOWED_OPTS = %i[global system local worktree file f blob].freeze
    private_constant :CONFIG_RENAME_SECTION_ALLOWED_OPTS

    # @overload config_rename_section(old_name, new_name, **options)
    #
    #   Rename a config section
    #
    #   Wraps `git config --rename-section`.
    #
    #   @example Rename a remote section
    #     repo.config_rename_section('remote.old', 'remote.new')
    #
    #   @param old_name [String] the current section name
    #
    #   @param new_name [String] the new section name
    #
    #   @param options [Hash] scope options
    #
    #   @option options [Boolean, nil] :global (nil) rename in `~/.gitconfig`
    #
    #   @option options [Boolean, nil] :system (nil) rename in the system config file
    #
    #   @option options [Boolean, nil] :local (nil) rename in `.git/config`
    #
    #   @option options [Boolean, nil] :worktree (nil) rename in the worktree config
    #
    #   @option options [String, nil] :file (nil) path to a custom config file (alias: `:f`)
    #
    #   @option options [String, nil] :blob (nil) rename in a git blob object
    #
    #   @return [nil]
    #
    #   @raise [ArgumentError] if unsupported options are provided
    #
    #   @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def config_rename_section(old_name, new_name, **)
      Private.assert_valid_opts!(CONFIG_RENAME_SECTION_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::RenameSection.new(execution_context)
      cmd.call(old_name, new_name, **)
      nil
    end

    # @api private
    CONFIG_REPLACE_ALL_ALLOWED_OPTS = %i[global system local worktree file f blob type].freeze
    private_constant :CONFIG_REPLACE_ALL_ALLOWED_OPTS

    # @overload config_replace_all(name, value, value_regex = nil, **options)
    #
    #   Replace all values matching a key and optional value regex
    #
    #   Wraps `git config --replace-all`.
    #
    #   @example Replace all values for a key
    #     repo.config_replace_all('remote.origin.url', 'https://github.com/user/repo')
    #
    #   @param name [String] the full dotted config key
    #
    #   @param value [String] the new value
    #
    #   @param value_regex [String, nil] optional regex; only matching values are replaced
    #
    #   @param options [Hash] scope options
    #
    #   @option options [Boolean, nil] :global (nil) write to `~/.gitconfig`
    #
    #   @option options [Boolean, nil] :system (nil) write to the system config file
    #
    #   @option options [Boolean, nil] :local (nil) write to `.git/config`
    #
    #   @option options [Boolean, nil] :worktree (nil) write to the worktree config
    #
    #   @option options [String, nil] :file (nil) path to a custom config file (alias: `:f`)
    #
    #   @option options [String, nil] :blob (nil) write to a git blob object
    #
    #   @option options [String, nil] :type (nil) coerce the value to the given type (e.g. `"bool"`, `"int"`)
    #
    #   @return [nil]
    #
    #   @raise [ArgumentError] if unsupported options are provided
    #
    #   @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def config_replace_all(name, value, value_regex = nil, **)
      Private.assert_valid_opts!(CONFIG_REPLACE_ALL_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::ReplaceAll.new(execution_context)
      cmd.call(name, value, value_regex, **)
      nil
    end

    # @api private
    CONFIG_SET_ALLOWED_OPTS = %i[global system local worktree file f blob type].freeze
    private_constant :CONFIG_SET_ALLOWED_OPTS

    # @overload config_set(name, value, **options)
    #
    #   Set a config entry to a new value
    #
    #   Wraps the implicit set mode of `git config`.
    #
    #   @example Set the user name in local config
    #     repo.config_set('user.name', 'Alice')
    #
    #   @param name [String] the full dotted config key
    #
    #   @param value [String] the value to set
    #
    #   @param options [Hash] scope options
    #
    #   @option options [Boolean, nil] :global (nil) write to `~/.gitconfig`
    #
    #   @option options [Boolean, nil] :system (nil) write to the system config file
    #
    #   @option options [Boolean, nil] :local (nil) write to `.git/config`
    #
    #   @option options [Boolean, nil] :worktree (nil) write to the worktree config
    #
    #   @option options [String, nil] :file (nil) path to a custom config file (alias: `:f`)
    #
    #   @option options [String, nil] :blob (nil) write to a git blob object
    #
    #   @option options [String, nil] :type (nil) coerce the value to the given type (e.g. `"bool"`, `"int"`)
    #
    #   @return [nil]
    #
    #   @raise [ArgumentError] if unsupported options are provided
    #
    #   @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def config_set(name, value, **)
      Private.assert_valid_opts!(CONFIG_SET_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::Set.new(execution_context)
      cmd.call(name, value, **)
      nil
    end

    # @api private
    CONFIG_UNSET_ALLOWED_OPTS = %i[global system local worktree file f blob].freeze
    private_constant :CONFIG_UNSET_ALLOWED_OPTS

    # @overload config_unset(name, value_regex = nil, **options)
    #
    #   Remove a config entry
    #
    #   Wraps `git config --unset`.
    #
    #   @example Remove a config entry
    #     repo.config_unset('user.name')
    #
    #   @param name [String] the full dotted config key
    #
    #   @param value_regex [String, nil] optional regex; only the matching value is removed
    #
    #   @param options [Hash] scope options
    #
    #   @option options [Boolean, nil] :global (nil) remove from `~/.gitconfig`
    #
    #   @option options [Boolean, nil] :system (nil) remove from the system config file
    #
    #   @option options [Boolean, nil] :local (nil) remove from `.git/config`
    #
    #   @option options [Boolean, nil] :worktree (nil) remove from the worktree config
    #
    #   @option options [String, nil] :file (nil) path to a custom config file (alias: `:f`)
    #
    #   @option options [String, nil] :blob (nil) remove from a git blob object
    #
    #   @return [nil]
    #
    #   @raise [ArgumentError] if unsupported options are provided
    #
    #   @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def config_unset(name, value_regex = nil, **)
      Private.assert_valid_opts!(CONFIG_UNSET_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::Unset.new(execution_context)
      cmd.call(name, value_regex, **)
      nil
    end

    # @api private
    CONFIG_UNSET_ALL_ALLOWED_OPTS = %i[global system local worktree file f blob].freeze
    private_constant :CONFIG_UNSET_ALL_ALLOWED_OPTS

    # @overload config_unset_all(name, value_regex = nil, **options)
    #
    #   Remove all config entries for a key
    #
    #   Wraps `git config --unset-all`.
    #
    #   @example Remove all values for a multi-valued key
    #     repo.config_unset_all('remote.origin.url')
    #
    #   @param name [String] the full dotted config key
    #
    #   @param value_regex [String, nil] optional regex; only matching values are removed
    #
    #   @param options [Hash] scope options
    #
    #   @option options [Boolean, nil] :global (nil) remove from `~/.gitconfig`
    #
    #   @option options [Boolean, nil] :system (nil) remove from the system config file
    #
    #   @option options [Boolean, nil] :local (nil) remove from `.git/config`
    #
    #   @option options [Boolean, nil] :worktree (nil) remove from the worktree config
    #
    #   @option options [String, nil] :file (nil) path to a custom config file (alias: `:f`)
    #
    #   @option options [String, nil] :blob (nil) remove from a git blob object
    #
    #   @return [nil]
    #
    #   @raise [ArgumentError] if unsupported options are provided
    #
    #   @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def config_unset_all(name, value_regex = nil, **)
      Private.assert_valid_opts!(CONFIG_UNSET_ALL_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::UnsetAll.new(execution_context)
      cmd.call(name, value_regex, **)
      nil
    end

    # @!endgroup

    private

    # @abstract
    #
    # Returns the execution context used to run git commands
    #
    # @return [Git::ExecutionContext]
    #
    def execution_context
      raise NotImplementedError
    end

    # @abstract
    #
    # @overload assert_valid_scope!(**options)
    #
    #   Validates that the requested scope options are appropriate for this context
    #
    #   Called before every config operation. Raise `ArgumentError` when a scope
    #   (e.g. `:local`) is not permitted without a repository.
    #
    #   @param options [Hash] scope options forwarded from the calling config method
    #
    #   @raise [ArgumentError] if the scope is not permitted in this context
    #
    #   @return [void]
    #
    def assert_valid_scope!(**)
      raise NotImplementedError
    end

    # Internal helpers for {Git::Configuring}.
    #
    # @api private
    #
    module Private
      module_function

      # Validate that candidate option keys are listed in `allowed`
      #
      # @param allowed [Array<Symbol>] the permitted option keys
      #
      # @param candidate_keywords [Hash<Symbol, Object>] the keywords to validate
      #
      # @option candidate_keywords [Object] key a candidate keyword value
      #
      # @return [void]
      #
      # @raise [ArgumentError] when any candidate key is not in `allowed`
      #
      def assert_valid_opts!(allowed, **candidate_keywords)
        unknown = candidate_keywords.keys - allowed
        return if unknown.empty?

        raise ArgumentError, "Unknown options: #{unknown.join(', ')}"
      end
    end

    private_constant :Private
  end
end
