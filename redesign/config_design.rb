# frozen_string_literal: true

# This is a forward looking document (in Ruby format) on the evolution of `git
# config` methods in Ruby Git. Here is how `git config` methods will change in
# v5.x and v6.x.
#
# In v5.x, `Git.config` and `Git.global_config` will continue to work as they do in
# v4.x but will be deprecated. New methods in the Git::Configuring module will be
# introduced in Git and Git::Repository to provide structured access to configuration
# entries. These will not be strict drop-in replacements for the existing deprecated
# methods.
#
# In v6.x, the deprecated methods will be removed.

# Top level Git module
module Git
  # Represents a single Git configuration entry
  #
  # @example
  #   scope = 'local'
  #   origin = 'path/to/config'
  #   key = 'remote.origin.url'
  #   value = 'https://github.com/ruby-git/ruby-git'
  #   entry = Git::ConfigEntryInfo.new(scope:, origin:, key: , value:)
  #
  # @!attribute [r] scope
  #
  #   The scope of the configuration entry
  #
  #   May be one of "system", "global", "local", "worktree", "file", or "blob".
  #
  #   @return [String]
  #
  # @!attribute [r] origin
  #
  #   Where the configuration entry originates
  #
  #   The origin is in the format: `<origin-type>:<actual-origin>`. It is never
  #   blank.
  #
  #   ### `origin-type`
  #
  #   This prefix explains the context of the configuration source. The four possible
  #   types are `file:`, `blob:`, `command line:`, and `standard input:`.
  #
  #   ### `actual-origin`
  #
  #   This provides the specific location for the configuration source. Only the
  #   `file:` and `blob:` origin types have an actual origin. For `command line:` and
  #   `standard input:`, Git drops this portion entirely and places the tab character
  #   immediately after the colon.
  #
  #   #### Path Resolution
  #
  #   When the origin type is a file, the actual origin can be formatted as either an
  #   absolute or relative path depending on how Git resolves it.
  #
  #     - **Absolute Paths**: Git outputs the full system path for system-level configurations,
  #       global configurations, explicitly provided absolute paths, or absolute
  #       paths used in [include] directives.
  #     - **Relative Paths**: Git outputs a relative path for local repository configurations,
  #       explicitly provided relative paths, or relative paths used in [include]
  #       directives.
  #     - **Relative Anchors**: Local repository paths are relative to the repository
  #       root. Command-line relative paths are relative to your current working
  #       directory. Relative paths from an [include] directive are anchored to
  #       the parent configuration file that included them.
  #
  #   @return [String]
  #
  # @!attribute [r] key
  #
  #   The full key name of the configuration entry (e.g., remote.origin.url)
  #
  #   @return [String]
  #
  # @!attribute [r] value
  #
  #   The value of the configuration entry
  #
  #   @return [String]
  #
  # @api public
  #
  ConfigEntryInfo = Data.define(:scope, :origin, :key, :value) do
    # Everything up to the first dot in the {key}
    #
    # Returns an empty string if {key} contains no dot.
    #
    # @example
    #   entry.section # => 'remote'
    #
    # @return [String]
    #
    def section = first_dot ? key[0...first_dot] : ''

    # Everything between the first and last dot in the {key}
    #
    # Returns an empty string if {key} has no subsection (zero or one dot).
    #
    # @example
    #   entry.subsection # => 'origin'
    #
    # @return [String]
    #
    def subsection = first_dot && first_dot != last_dot ? key[(first_dot + 1)...last_dot] : ''

    # Everything after the last dot in the {key}
    #
    # Returns the full {key} if {key} contains no dot.
    #
    # @example
    #   entry.variable # => 'url'
    #
    # @return [String]
    #
    def variable = last_dot ? key[(last_dot + 1)..] : key

    private

    def first_dot = key.index('.')

    def last_dot = key.rindex('.')
  end

  module Parsers
    # Parser for `git config --get` and `git config --list` output
    # when called with `--show-scope --show-origin --null`.
    #
    # @api private
    #
    module ConfigEntry
      module_function

      # Parse `git config --get --show-scope --show-origin --null` output.
      #
      # Output format (per entry): `scope\0origin\0value\0`
      # The key name is not present in --get output; it must be supplied.
      #
      # @param key [String] the config key name that was queried
      # @param output [String] raw stdout from the command
      # @return [Git::ConfigEntryInfo, nil] the parsed entry, or nil if not found
      #
      def parse_get(key, output)
        return nil if output.empty?

        scope, origin, value = output.split("\0", -1)
        Git::ConfigEntryInfo.new(scope: scope, origin: origin, key: key, value: value)
      end

      # Parse `git config --get-all --show-scope --show-origin --null` output.
      #
      # Output format (per entry): `scope\0origin\0value\0`
      # The key name is not present in --get-all output; it must be supplied.
      # Entries repeat back-to-back in the same string.
      #
      # @param key [String] the config key name that was queried
      # @param output [String] raw stdout from the command
      # @return [Array<Git::ConfigEntryInfo>] the parsed entries
      #
      def parse_get_all(key, output)
        return [] if output.empty?

        tokens = output.split("\0", -1)
        tokens.pop if tokens.last && tokens.last.empty?
        tokens.each_slice(3).map do |scope, origin, value|
          Git::ConfigEntryInfo.new(scope: scope, origin: origin, key: key, value: value)
        end
      end

      # Parse `git config --list --show-scope --show-origin --null` output.
      #
      # Also used for `--get-regexp` and `--get-urlmatch` output, which share
      # the same format.
      #
      # Output format (per entry): `scope\0origin\0key\nvalue\0`
      # Entries repeat back-to-back in the same string.
      #
      # @param output [String] raw stdout from the command
      # @return [Array<Git::ConfigEntryInfo>] the parsed entries
      #
      def parse_list(output)
        return [] if output.empty?

        tokens = output.split("\0", -1)
        tokens.pop if tokens.last && tokens.last.empty?
        tokens.each_slice(3).map do |scope, origin, key_value|
          key, value = key_value.split("\n", 2)
          Git::ConfigEntryInfo.new(scope: scope, origin: origin, key: key, value: value || '')
        end
      end
    end
  end

  # Designed to be included in the Git module and the Git::Repository module
  #
  # The including/extending class must implement {#execution_context} and
  # {#assert_valid_scope!}.
  #
  module Configuring # rubocop:disable Metrics/ModuleLength
    # @!group Read Operations

    CONFIG_GET_ALLOWED_OPTS = %i[global system local worktree file f blob includes no_includes type default].freeze
    private_constant :CONFIG_GET_ALLOWED_OPTS

    # @return [Git::ConfigEntryInfo, nil] nil if the key is not found
    def config_get(name, value_regex = nil, **options)
      Private.assert_valid_opts!(CONFIG_GET_ALLOWED_OPTS, **options)
      assert_valid_scope!(**options)
      options = options.merge(show_scope: true, show_origin: true, null: true)
      cmd = Git::Commands::ConfigOptionSyntax::Get.new(execution_context)
      output = cmd.call(name, value_regex, **options).stdout
      Git::Parsers::ConfigEntry.parse_get(name, output)
    end

    CONFIG_GET_ALL_ALLOWED_OPTS = %i[global system local worktree file f blob includes no_includes type].freeze
    private_constant :CONFIG_GET_ALL_ALLOWED_OPTS

    # @return [Array<Git::ConfigEntryInfo>]
    def config_get_all(name, value_regex = nil, **options)
      Private.assert_valid_opts!(CONFIG_GET_ALL_ALLOWED_OPTS, **options)
      assert_valid_scope!(**options)
      options = options.merge(show_scope: true, show_origin: true, null: true)
      cmd = Git::Commands::ConfigOptionSyntax::GetAll.new(execution_context)
      output = cmd.call(name, value_regex, **options).stdout
      Git::Parsers::ConfigEntry.parse_get_all(name, output)
    end

    # `git config --get --type=color [--default=<default>]` is preferred over
    # --get-color
    #
    # def config_get_color(name, default = nil, **)
    #   ...
    # end

    CONFIG_GET_COLORBOOL_ALLOWED_OPTS = %i[global system local worktree file f blob includes no_includes].freeze
    private_constant :CONFIG_GET_COLORBOOL_ALLOWED_OPTS

    # @return [String] always 'true' or 'false'
    def config_get_colorbool(name, stdout_is_tty = nil, **)
      Private.assert_valid_opts!(CONFIG_GET_COLORBOOL_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::GetColorBool.new(execution_context)
      cmd.call(name, stdout_is_tty, **).stdout.chomp
    end

    CONFIG_GET_REGEXP_ALLOWED_OPTS = %i[global system local worktree file f blob includes no_includes type].freeze
    private_constant :CONFIG_GET_REGEXP_ALLOWED_OPTS

    # @return [Array<Git::ConfigEntryInfo>]
    def config_get_regexp(name_regex, value_regex = nil, **options)
      Private.assert_valid_opts!(CONFIG_GET_REGEXP_ALLOWED_OPTS, **options)
      assert_valid_scope!(**options)
      options = options.merge(show_scope: true, show_origin: true, null: true)
      cmd = Git::Commands::ConfigOptionSyntax::GetRegexp.new(execution_context)
      output = cmd.call(name_regex, value_regex, **options).stdout
      Git::Parsers::ConfigEntry.parse_list(output)
    end

    CONFIG_GET_URLMATCH_ALLOWED_OPTS = %i[global system local worktree file f blob includes no_includes type].freeze
    private_constant :CONFIG_GET_URLMATCH_ALLOWED_OPTS

    # @return [Array<Git::ConfigEntryInfo>]
    def config_get_urlmatch(name, url, **options)
      Private.assert_valid_opts!(CONFIG_GET_URLMATCH_ALLOWED_OPTS, **options)
      assert_valid_scope!(**options)
      options = options.merge(show_scope: true, show_origin: true, null: true)
      cmd = Git::Commands::ConfigOptionSyntax::GetUrlmatch.new(execution_context)
      output = cmd.call(name, url, **options).stdout
      Git::Parsers::ConfigEntry.parse_list(output)
    end

    CONFIG_LIST_ALLOWED_OPTS = %i[global system local worktree file f blob includes no_includes type].freeze
    private_constant :CONFIG_LIST_ALLOWED_OPTS

    # @return [Array<Git::ConfigEntryInfo>]
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

    CONFIG_ADD_ALLOWED_OPTS = %i[global system local worktree file f blob type].freeze
    private_constant :CONFIG_ADD_ALLOWED_OPTS

    # @return [void]
    #
    # @raise [ArgumentError] if unsupported options are provided
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    def config_add(name, value, **)
      Private.assert_valid_opts!(CONFIG_ADD_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::Add.new(execution_context)
      cmd.call(name, value, **)
      nil
    end

    CONFIG_REMOVE_SECTION_ALLOWED_OPTS = %i[global system local worktree file f blob].freeze
    private_constant :CONFIG_REMOVE_SECTION_ALLOWED_OPTS

    # @return [void]
    #
    # @raise [ArgumentError] if unsupported options are provided
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    def config_remove_section(name, **)
      Private.assert_valid_opts!(CONFIG_REMOVE_SECTION_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::RemoveSection.new(execution_context)
      cmd.call(name, **)
      nil
    end

    CONFIG_RENAME_SECTION_ALLOWED_OPTS = %i[global system local worktree file f blob].freeze
    private_constant :CONFIG_RENAME_SECTION_ALLOWED_OPTS

    # @return [void]
    #
    # @raise [ArgumentError] if unsupported options are provided
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    def config_rename_section(old_name, new_name, **)
      Private.assert_valid_opts!(CONFIG_RENAME_SECTION_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::RenameSection.new(execution_context)
      cmd.call(old_name, new_name, **)
      nil
    end

    CONFIG_REPLACE_ALL_ALLOWED_OPTS = %i[global system local worktree file f blob type].freeze
    private_constant :CONFIG_REPLACE_ALL_ALLOWED_OPTS

    # @return [void]
    #
    # @raise [ArgumentError] if unsupported options are provided
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    def config_replace_all(name, value, value_regex = nil, **)
      Private.assert_valid_opts!(CONFIG_REPLACE_ALL_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::ReplaceAll.new(execution_context)
      cmd.call(name, value, value_regex, **)
      nil
    end

    CONFIG_SET_ALLOWED_OPTS = %i[global system local worktree file f blob type].freeze
    private_constant :CONFIG_SET_ALLOWED_OPTS

    # @return [void]
    #
    # @raise [ArgumentError] if unsupported options are provided
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    def config_set(name, value, **)
      Private.assert_valid_opts!(CONFIG_SET_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::Set.new(execution_context)
      cmd.call(name, value, **)
      nil
    end

    CONFIG_UNSET_ALLOWED_OPTS = %i[global system local worktree file f blob].freeze
    private_constant :CONFIG_UNSET_ALLOWED_OPTS

    # @return [void]
    #
    # @raise [ArgumentError] if unsupported options are provided
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    def config_unset(name, value_regex = nil, **)
      Private.assert_valid_opts!(CONFIG_UNSET_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::Unset.new(execution_context)
      cmd.call(name, value_regex, **)
      nil
    end

    CONFIG_UNSET_ALL_ALLOWED_OPTS = %i[global system local worktree file f blob].freeze
    private_constant :CONFIG_UNSET_ALL_ALLOWED_OPTS

    # @return [void]
    #
    # @raise [ArgumentError] if unsupported options are provided
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    def config_unset_all(name, value_regex = nil, **)
      Private.assert_valid_opts!(CONFIG_UNSET_ALL_ALLOWED_OPTS, **)
      assert_valid_scope!(**)
      cmd = Git::Commands::ConfigOptionSyntax::UnsetAll.new(execution_context)
      cmd.call(name, value_regex, **)
      nil
    end

    # @!endgroup

    private

    # @abstract Including/extending class must implement execution_context
    #
    # @return [Git::ExecutionContext]
    #
    def execution_context
      raise NotImplementedError
    end

    # @abstract Including/extending class must implement assert_valid_scope!
    #
    # Called before every config operation to validate that the requested scope
    # is appropriate for the context (e.g., repository-specific scopes such as
    # `local` are not valid when called without a repository).
    #
    # @raise [ArgumentError] if the scope is not permitted in this context
    #
    # @return [void]
    #
    def assert_valid_scope!(**)
      raise NotImplementedError
    end

    # Internal helpers local to {Git::Configuring}
    #
    # @api private
    #
    module Private
      module_function

      # Validate that `options` contains only keys listed in `allowed`
      #
      # @example Reject an undocumented option
      #   Private.assert_valid_opts!(%i[all force], bogus: true)
      #   #=> raises ArgumentError: Unknown options: bogus
      #
      # @param allowed [Array<Symbol>] the keys permitted by the facade method
      #
      # @param options [Hash] the options hash provided by the caller
      #
      # @return [void]
      #
      # @raise [ArgumentError] when `options` contains any key not in `allowed`
      #
      def assert_valid_opts!(allowed, **options)
        unknown = options.keys - allowed
        return if unknown.empty?

        raise ArgumentError, "Unknown options: #{unknown.join(', ')}"
      end
    end
    private_constant :Private
  end

  REPOSITORY_SPECIFIC_SCOPES = %i[local worktree blob].freeze
  private_constant :REPOSITORY_SPECIFIC_SCOPES

  # Reopens Git::Repository to mix in config read/write operations.
  #
  # In the real implementation this `include` lives in
  # `lib/git/repository/configuring.rb` and is picked up by the
  # `Git::Repository` class definition in `lib/git/repository.rb`.
  class Repository
    # Mixes in config_get, config_list, config_set, etc.
    include Git::Configuring

    private

    # @return [Git::ExecutionContext::Repository]
    attr_reader :execution_context

    # All scopes are permitted when called with a repository context.
    def assert_valid_scope!(**)
      # All scopes allowed
    end
  end

  # Enables calling Git.config_get('user.name')
  extend Git::Configuring

  # Returns a global execution context for non-repository config operations.
  #
  # Overrides the abstract {Git::Configuring#execution_context} for the
  # module-level case.
  #
  # @return [Git::ExecutionContext::Global]
  def self.execution_context
    Git::ExecutionContext::Global.new
  end
  private_class_method :execution_context

  def self.assert_valid_scope!(**options)
    repo_scopes = options.keys.select { |k| options[k] && REPOSITORY_SPECIFIC_SCOPES.include?(k) }
    raise ArgumentError, "scope #{repo_scopes.first} requires a repository" if repo_scopes.any?
  end
  private_class_method :assert_valid_scope!
end
