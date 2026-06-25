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

  describe '.global_config', skip: unless_git('2.32.0', 'GIT_CONFIG_GLOBAL isolation') do
    around { |example| with_isolated_global_config { example.run } }

    context 'when called with no arguments (list mode)' do
      before do
        Git.config_set('user.name', 'GlobalUser', global: true)
        Git.config_set('user.email', 'global@example.com', global: true)
      end

      it 'returns a Hash' do
        expect(Git.global_config).to be_a(Hash)
      end

      it 'includes the written entries keyed by dotted name' do
        result = Git.global_config
        expect(result).to include('user.name' => 'GlobalUser', 'user.email' => 'global@example.com')
      end
    end

    context 'when called with a name only (get mode)' do
      before { Git.config_set('user.name', 'GlobalUser', global: true) }

      it 'returns the String value for the named key' do
        expect(Git.global_config('user.name')).to eq('GlobalUser')
      end

      it 'raises Git::FailedError when the key does not exist' do
        expect { Git.global_config('ruby-git-rspec.nonexistent-key') }.to raise_error(Git::FailedError)
      end
    end

    context 'when called with name and value (set mode)' do
      it 'persists the value so a subsequent get returns it' do
        Git.global_config('user.name', 'SetUser')

        expect(Git.global_config('user.name')).to eq('SetUser')
      end
    end
  end
end
