# frozen_string_literal: true

require 'spec_helper'

# Backward-compatibility integration tests for Git::Lib config methods.
# These verify that the public API of Git::Lib is preserved after the methods
# were delegated to Git::Commands::ConfigOptionSyntax::* classes.
RSpec.describe Git::Lib, :integration do
  include_context 'in an empty repository'

  subject(:lib) { repo.lib }

  # --- config_get ---

  describe '#config_get' do
    it 'returns the value for an existing key' do
      lib.config_set('user.name', 'Test User')
      expect(lib.config_get('user.name')).to eq('Test User')
    end

    it 'raises Git::FailedError for a missing key' do
      expect { lib.config_get('section.missing.key') }
        .to raise_error(Git::FailedError)
    end
  end

  # --- config_list ---

  describe '#config_list' do
    it 'returns a Hash of all local config entries' do
      lib.config_set('user.name', 'Test User')
      lib.config_set('user.email', 'test@example.com')
      result = lib.config_list
      expect(result).to be_a(Hash)
      expect(result['user.name']).to eq('Test User')
      expect(result['user.email']).to eq('test@example.com')
    end
  end

  # --- parse_config ---

  describe '#parse_config' do
    it 'returns a Hash of all entries in the given file' do
      config_file = File.join(repo_dir, 'my.config')
      File.write(config_file, "[section]\n\tkey = value\n")
      result = lib.parse_config(config_file)
      expect(result).to be_a(Hash)
      expect(result['section.key']).to eq('value')
    end
  end

  # --- config_set ---

  describe '#config_set' do
    it 'writes a local config value readable by config_get' do
      lib.config_set('section.key', 'hello')
      expect(lib.config_get('section.key')).to eq('hello')
    end

    it 'writes to the specified file when file: is given' do
      config_file = File.join(repo_dir, 'custom.config')
      lib.config_set('section.key', 'file_value', file: config_file)
      result = lib.parse_config(config_file)
      expect(result['section.key']).to eq('file_value')
    end
  end

  # --- global config methods ---
  #
  # GIT_CONFIG_GLOBAL is redirected to a temp file for the duration of each
  # example so the real ~/.gitconfig is never read or modified.

  describe '#global_config_get' do
    around do |example|
      with_isolated_global_config { example.run }
    end

    it 'returns the value for an existing key' do
      lib.global_config_set('user.name', 'Global User')
      expect(lib.global_config_get('user.name')).to eq('Global User')
    end

    it 'raises Git::FailedError for a missing key' do
      expect { lib.global_config_get('section.missing.key') }
        .to raise_error(Git::FailedError)
    end
  end

  describe '#global_config_list' do
    around do |example|
      with_isolated_global_config { example.run }
    end

    it 'returns a Hash of global config entries' do
      lib.global_config_set('user.name', 'Global User')
      lib.global_config_set('user.email', 'global@example.com')
      result = lib.global_config_list
      expect(result).to be_a(Hash)
      expect(result['user.name']).to eq('Global User')
      expect(result['user.email']).to eq('global@example.com')
    end
  end

  describe '#global_config_set' do
    around do |example|
      with_isolated_global_config { example.run }
    end

    it 'writes a global config value readable by global_config_get' do
      lib.global_config_set('user.name', 'Global User')
      expect(lib.global_config_get('user.name')).to eq('Global User')
    end
  end

  # Helpers

  def with_isolated_global_config
    global_config = File.join(repo_dir, 'global.config')
    FileUtils.touch(global_config)
    saved = ENV.fetch('GIT_CONFIG_GLOBAL', nil)
    ENV['GIT_CONFIG_GLOBAL'] = global_config
    yield
  ensure
    saved.nil? ? ENV.delete('GIT_CONFIG_GLOBAL') : ENV['GIT_CONFIG_GLOBAL'] = saved
  end
end
