# frozen_string_literal: true

require 'spec_helper'
require 'git/config_entry_info'
require 'git/parsers/config_entry'
require 'git/commands/config_option_syntax/add'
require 'git/commands/config_option_syntax/get'
require 'git/commands/config_option_syntax/get_all'
require 'git/commands/config_option_syntax/get_urlmatch'
require 'git/commands/config_option_syntax/list'
require 'git/commands/config_option_syntax/set'

# Integration tests for Git::Parsers::ConfigEntry
#
# These tests verify that the parser correctly handles real git output.
# They validate that the format assumptions in unit test fixtures match the
# actual output produced by git when called with --null --show-scope --show-origin
# (or --show-scope only for parse_urlmatch, where --show-origin is unsupported).
#
RSpec.describe Git::Parsers::ConfigEntry, :integration do
  include_context 'in an empty repository'

  describe '.parse_get' do
    context 'when called against real git output' do
      it 'returns a ConfigEntryInfo with the correct scope, origin, key, and value' do
        cmd = Git::Commands::ConfigOptionSyntax::Get.new(execution_context)
        raw = cmd.call('user.name', local: true, show_scope: true, show_origin: true, null: true).stdout

        result = described_class.parse_get('user.name', raw)

        expect(result).to be_a(Git::ConfigEntryInfo)
        expect(result.scope).to eq('local')
        expect(result.origin).to match(%r{file:.*\.git[/\\]config})
        expect(result.key).to eq('user.name')
        expect(result.value).to eq('Test User')
      end

      it 'returns nil when the key does not exist' do
        cmd = Git::Commands::ConfigOptionSyntax::Get.new(execution_context)
        raw = cmd.call('nonexistent.key', local: true, show_scope: true, show_origin: true, null: true).stdout

        result = described_class.parse_get('nonexistent.key', raw)

        expect(result).to be_nil
      end
    end
  end

  describe '.parse_get_all' do
    context 'with a single-valued key' do
      it 'returns an array with one correctly-parsed ConfigEntryInfo' do
        cmd = Git::Commands::ConfigOptionSyntax::GetAll.new(execution_context)
        raw = cmd.call('user.name', local: true, show_scope: true, show_origin: true, null: true).stdout

        result = described_class.parse_get_all('user.name', raw)

        expect(result.size).to eq(1)
        expect(result[0]).to be_a(Git::ConfigEntryInfo)
        expect(result[0].scope).to eq('local')
        expect(result[0].origin).to match(%r{file:.*\.git[/\\]config})
        expect(result[0].key).to eq('user.name')
        expect(result[0].value).to eq('Test User')
      end
    end

    context 'with a multi-valued key' do
      before do
        set_cmd = Git::Commands::ConfigOptionSyntax::Set.new(execution_context)
        set_cmd.call('remote.origin.url', 'https://github.com/ruby-git/ruby-git', local: true)
        add_cmd = Git::Commands::ConfigOptionSyntax::Add.new(execution_context)
        add_cmd.call('remote.origin.url', 'git@github.com:ruby-git/ruby-git.git', local: true)
      end

      it 'returns one ConfigEntryInfo per value' do
        cmd = Git::Commands::ConfigOptionSyntax::GetAll.new(execution_context)
        opts = { local: true, show_scope: true, show_origin: true, null: true }
        raw = cmd.call('remote.origin.url', **opts).stdout

        result = described_class.parse_get_all('remote.origin.url', raw)

        expect(result.size).to eq(2)
        expect(result.map(&:value)).to contain_exactly(
          'https://github.com/ruby-git/ruby-git',
          'git@github.com:ruby-git/ruby-git.git'
        )
        result.each do |entry|
          expect(entry.key).to eq('remote.origin.url')
          expect(entry.scope).to eq('local')
          expect(entry.origin).to match(%r{file:.*\.git[/\\]config})
        end
      end
    end

    context 'when the key does not exist' do
      it 'returns an empty array' do
        cmd = Git::Commands::ConfigOptionSyntax::GetAll.new(execution_context)
        raw = cmd.call('nonexistent.key', local: true, show_scope: true, show_origin: true, null: true).stdout

        result = described_class.parse_get_all('nonexistent.key', raw)

        expect(result).to eq([])
      end
    end
  end

  describe '.parse_list' do
    let(:list_cmd) { Git::Commands::ConfigOptionSyntax::List.new(execution_context) }
    let(:list_opts) { { local: true, show_scope: true, show_origin: true, null: true } }

    context 'when called against real git list output' do
      it 'returns at least one entry with the correct structure for each field' do
        result = described_class.parse_list(list_cmd.call(**list_opts).stdout)

        expect(result).to be_an(Array)
        expect(result).not_to be_empty
        result.each do |entry|
          expect(entry).to be_a(Git::ConfigEntryInfo)
          expect(entry.scope).not_to be_empty
          expect(entry.origin).not_to be_empty
          expect(entry.key).not_to be_empty
        end
      end

      it 'includes the user.name entry set during test setup' do
        result = described_class.parse_list(list_cmd.call(**list_opts).stdout)

        user_name_entry = result.find { |e| e.key == 'user.name' }
        expect(user_name_entry).not_to be_nil
        expect(user_name_entry.value).to eq('Test User')
        expect(user_name_entry.scope).to eq('local')
        expect(user_name_entry.origin).to match(%r{file:.*\.git[/\\]config})
      end
    end
  end

  describe '.parse_urlmatch' do
    let(:urlmatch_cmd) { Git::Commands::ConfigOptionSyntax::GetUrlmatch.new(execution_context) }

    context 'when called against real git get-urlmatch output' do
      before do
        set_cmd = Git::Commands::ConfigOptionSyntax::Set.new(execution_context)
        set_cmd.call('http.https://example.com.proxy', 'http://proxy.example.com', local: true)
      end

      it 'returns a ConfigEntryInfo with scope, key, and value populated' do
        raw = urlmatch_cmd.call('http.proxy', 'https://example.com', local: true, show_scope: true, null: true).stdout

        result = described_class.parse_urlmatch(raw)

        expect(result).to be_an(Array)
        expect(result).not_to be_empty
        result.each do |entry|
          expect(entry).to be_a(Git::ConfigEntryInfo)
          expect(entry.scope).to eq('local')
          expect(entry.key).not_to be_empty
          expect(entry.value).not_to be_nil
        end
      end

      it 'sets origin to nil because --show-origin is unsupported for --get-urlmatch' do
        raw = urlmatch_cmd.call('http.proxy', 'https://example.com', local: true, show_scope: true, null: true).stdout

        result = described_class.parse_urlmatch(raw)

        expect(result).not_to be_empty
        result.each { |entry| expect(entry.origin).to be_nil }
      end

      it 'returns an empty array when no URL matches' do
        raw = urlmatch_cmd.call(
          'http.proxy', 'https://nomatch.example.com', local: true, show_scope: true, null: true
        ).stdout

        expect(described_class.parse_urlmatch(raw)).to eq([])
      end
    end
  end
end
