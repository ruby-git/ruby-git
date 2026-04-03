# frozen_string_literal: true

module Git
  module Commands
    # Implements the `git config` command using the option-based interface
    #
    # This module contains command classes for the pre-2.46.0 option-based
    # `git config` interface (`--get`, `--list`, `--add`, etc.):
    #
    # **Read operations:**
    # - {ConfigOptionSyntax::Get} — retrieve a single value (`--get`)
    # - {ConfigOptionSyntax::GetAll} — retrieve all values for a multi-valued key (`--get-all`)
    # - {ConfigOptionSyntax::GetRegexp} — retrieve values matching a name regex (`--get-regexp`)
    # - {ConfigOptionSyntax::GetUrlmatch} — retrieve URL-matched values (`--get-urlmatch`)
    # - {ConfigOptionSyntax::GetColor} — retrieve an ANSI color string (`--get-color`)
    # - {ConfigOptionSyntax::GetColorBool} — query whether color output is enabled (`--get-colorbool`)
    # - {ConfigOptionSyntax::List} — list all config entries (`--list`)
    #
    # **Write operations:**
    # - {ConfigOptionSyntax::Set} — set a config value (implicit set mode)
    # - {ConfigOptionSyntax::Add} — append a value to a multi-valued key (`--add`)
    # - {ConfigOptionSyntax::ReplaceAll} — replace all matching values (`--replace-all`)
    #
    # **Delete operations:**
    # - {ConfigOptionSyntax::Unset} — remove a single value (`--unset`)
    # - {ConfigOptionSyntax::UnsetAll} — remove all matching values (`--unset-all`)
    #
    # **Section operations:**
    # - {ConfigOptionSyntax::RenameSection} — rename a config section (`--rename-section`)
    # - {ConfigOptionSyntax::RemoveSection} — remove a config section (`--remove-section`)
    #
    # @see https://git-scm.com/docs/git-config/2.28.0 git-config documentation (v2.28.0)
    #
    # @see Git::Commands
    #
    # @api private
    #
    module ConfigOptionSyntax
    end
  end
end
