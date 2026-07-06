# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git do
  # Redirect GIT_CONFIG_GLOBAL to a temp file so each example starts with a
  # known, clean slate and the developer's real ~/.gitconfig is never touched.
  def with_isolated_global_config
    Dir.mktmpdir do |dir|
      global_config = File.join(dir, 'global.config')
      FileUtils.touch(global_config)
      saved = ENV.fetch('GIT_CONFIG_GLOBAL', nil)
      ENV['GIT_CONFIG_GLOBAL'] = global_config
      yield global_config
    ensure
      saved.nil? ? ENV.delete('GIT_CONFIG_GLOBAL') : ENV['GIT_CONFIG_GLOBAL'] = saved
    end
  end

  describe '.config_get' do
    around { |example| with_isolated_global_config { example.run } }

    before do
      Git.config_set('integration.key', 'hello', global: true)
    end

    it 'returns a Git::ConfigEntryInfo for an existing key' do
      entry = Git.config_get('integration.key', global: true)

      expect(entry).to be_a(Git::ConfigEntryInfo)
      expect(entry.value).to eq('hello')
    end

    it 'returns nil when the key does not exist' do
      entry = Git.config_get('nonexistent.key', global: true)

      expect(entry).to be_nil
    end
  end

  describe '.config_list' do
    around { |example| with_isolated_global_config { example.run } }

    before do
      Git.config_set('integration.key', 'hello', global: true)
      Git.config_set('integration.other', 'world', global: true)
    end

    it 'returns an Array of Git::ConfigEntryInfo objects' do
      entries = Git.config_list(global: true)

      expect(entries).to be_an(Array)
      expect(entries).to all(be_a(Git::ConfigEntryInfo))
    end

    it 'includes entries for the written keys' do
      entries = Git.config_list(global: true)

      keys = entries.map(&:key)
      expect(keys).to include('integration.key', 'integration.other')
    end
  end
end
