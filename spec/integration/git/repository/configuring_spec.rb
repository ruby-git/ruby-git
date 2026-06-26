# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/configuring'

# Integration tests for deprecated Git::Repository#config and #global_config.
#
# #config (list mode) performs facade-owned post-processing: it parses the raw
# stdout of `git config --list` into a Ruby Hash. A real git invocation is
# needed to confirm the parsing handles actual git output correctly.
#
# Single-command get and set modes are covered by dedicated command integration
# tests under spec/integration/git/commands/config_option_syntax/{get,set,list}_spec.rb.
# Argument-forwarding tests are skipped here because they test command behavior,
# not the facade. The missing-key error path is retained to pin the 4.x-equivalent
# dispatch contract: #config(name) must propagate Git::FailedError when git exits
# non-zero, which is facade behavior (Private.config_get raises on a non-zero exit). The
# set→get round-trip test is retained to confirm the facade's dispatch logic routes
# both modes correctly end-to-end against real git.

RSpec.describe Git::Repository, :integration do
  include_context 'in an empty repository'

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#config' do
    context 'when called with no arguments' do
      it 'returns a Hash containing expected config keys' do
        result = described_instance.config
        expect(result).to be_a(Hash)
        expect(result).to include('user.name', 'user.email')
      end

      it 'returns the configured user.name value' do
        result = described_instance.config
        expect(result['user.name']).to eq('Test User')
      end
    end

    context 'when called with a name only' do
      it 'returns the config value as a String' do
        expect(described_instance.config('user.name')).to eq('Test User')
      end

      it 'raises Git::FailedError when the key does not exist' do
        expect { described_instance.config('ruby-git-rspec.nonexistent-key') }.to raise_error(Git::FailedError)
      end
    end

    context 'when called with name and value' do
      it 'sets the value and a subsequent get returns the new value' do
        described_instance.config('user.name', 'NewName')
        expect(described_instance.config('user.name')).to eq('NewName')
      end
    end

    context 'when called with a file: option pointing to a real file' do
      let(:config_file) { File.join(repo_dir, 'custom.config') }

      it 'returns a Hash of all entries in the given config file' do
        File.write(config_file, "[section]\n\tkey = value\n")
        result = described_instance.config(file: config_file)
        expect(result).to be_a(Hash)
        expect(result['section.key']).to eq('value')
      end
    end

    context 'when writing with a file: option then reading back' do
      let(:config_file) { File.join(repo_dir, 'custom.config') }

      it 'persists the value to the specified file' do
        described_instance.config('section.key', 'file_value', file: config_file)
        result = described_instance.config(file: config_file)
        expect(result['section.key']).to eq('file_value')
      end
    end
  end

  describe '#global_config', skip: unless_git('2.32.0', 'GIT_CONFIG_GLOBAL isolation') do
    around do |example|
      with_isolated_global_config { example.run }
    end

    context 'when called with no arguments' do
      before do
        described_instance.global_config('user.name', 'GlobalUser')
        described_instance.global_config('user.email', 'global@example.com')
      end

      it 'returns a Hash containing the written global config entries' do
        result = described_instance.global_config
        expect(result).to be_a(Hash)
        expect(result).to include('user.name' => 'GlobalUser', 'user.email' => 'global@example.com')
      end
    end

    context 'when called with a name' do
      before { described_instance.global_config('user.name', 'GlobalUser') }

      it 'returns the String value for the named key from global config' do
        expect(described_instance.global_config('user.name')).to eq('GlobalUser')
      end
    end

    context 'when called with name and value' do
      it 'persists the value so a subsequent get returns it' do
        described_instance.global_config('user.name', 'SetUser')

        expect(described_instance.global_config('user.name')).to eq('SetUser')
      end
    end

    def with_isolated_global_config
      saved = ENV.fetch('GIT_CONFIG_GLOBAL', nil)
      global_config = File.join(repo_dir, 'global.config')
      File.write(global_config, '')
      ENV['GIT_CONFIG_GLOBAL'] = global_config
      yield
    ensure
      saved.nil? ? ENV.delete('GIT_CONFIG_GLOBAL') : ENV['GIT_CONFIG_GLOBAL'] = saved
    end
  end
end
