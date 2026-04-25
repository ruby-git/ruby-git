# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::ExecutionContext do
  describe 'constants' do
    it 'defines COMMAND_CAPTURING_ARG_DEFAULTS' do
      expect(described_class::COMMAND_CAPTURING_ARG_DEFAULTS).to be_a(Hash)
      expect(described_class::COMMAND_CAPTURING_ARG_DEFAULTS).to include(:normalize, :chomp, :raise_on_failure)
    end

    it 'defines COMMAND_STREAMING_ARG_DEFAULTS' do
      expect(described_class::COMMAND_STREAMING_ARG_DEFAULTS).to be_a(Hash)
      expect(described_class::COMMAND_STREAMING_ARG_DEFAULTS).to include(:raise_on_failure)
    end

    it 'defines STATIC_GLOBAL_OPTS' do
      expect(described_class::STATIC_GLOBAL_OPTS).to be_a(Array)
      expect(described_class::STATIC_GLOBAL_OPTS).to include('-c', 'core.quotePath=true')
    end
  end

  describe 'accessor defaults' do
    let(:context) { described_class.new }

    it 'returns nil for git_dir' do
      expect(context.git_dir).to be_nil
    end

    it 'returns nil for git_work_dir' do
      expect(context.git_work_dir).to be_nil
    end

    it 'returns nil for git_index_file' do
      expect(context.git_index_file).to be_nil
    end

    it 'delegates git_ssh to Git::Base.config by default' do
      allow(Git::Base).to receive_message_chain(:config, :git_ssh).and_return('/configured/ssh')
      expect(context.git_ssh).to eq('/configured/ssh')
    end

    it 'returns nil for git_ssh when explicitly passed nil' do
      expect(described_class.new(git_ssh: nil).git_ssh).to be_nil
    end

    it 'returns a literal git_ssh path when provided' do
      expect(described_class.new(git_ssh: '/usr/bin/ssh').git_ssh).to eq('/usr/bin/ssh')
    end
  end

  describe 'env_overrides (via #send)' do
    let(:context) { described_class.new(git_ssh: nil) }

    it 'returns GIT_DIR as nil by default' do
      expect(context.send(:env_overrides)['GIT_DIR']).to be_nil
    end

    it 'returns GIT_WORK_TREE as nil by default' do
      expect(context.send(:env_overrides)['GIT_WORK_TREE']).to be_nil
    end

    it 'returns GIT_INDEX_FILE as nil by default' do
      expect(context.send(:env_overrides)['GIT_INDEX_FILE']).to be_nil
    end

    it 'returns GIT_SSH as nil when git_ssh is nil' do
      expect(context.send(:env_overrides)['GIT_SSH']).to be_nil
    end

    it 'sets GIT_EDITOR to "true"' do
      expect(context.send(:env_overrides)['GIT_EDITOR']).to eq('true')
    end

    it 'sets LC_ALL to "en_US.UTF-8"' do
      expect(context.send(:env_overrides)['LC_ALL']).to eq('en_US.UTF-8')
    end

    it 'merges caller-supplied additional overrides' do
      env = context.send(:env_overrides, 'GIT_TRACE' => '1')
      expect(env['GIT_TRACE']).to eq('1')
    end
  end

  describe 'global_opts (via #send)' do
    it 'includes only static opts when git_dir and git_work_dir are nil' do
      context = described_class.new
      expect(context.send(:global_opts)).to eq(described_class::STATIC_GLOBAL_OPTS)
    end
  end

  describe '#command_capturing' do
    let(:context) { described_class.new }
    let(:command_line_double) { instance_double(Git::CommandLine::Capturing) }
    let(:result) { command_result('output') }

    before do
      allow(context).to receive(:command_line_capturing).and_return(command_line_double)
      allow(Git::Base).to receive_message_chain(:config, :timeout).and_return(nil)
    end

    it 'delegates to command_line_capturing.run with defaults' do
      expect(command_line_double).to receive(:run)
        .with('version', hash_including(raise_on_failure: true, normalize: true, chomp: true))
        .and_return(result)
      context.command_capturing('version')
    end

    it 'raises ArgumentError for unknown option keys' do
      expect { context.command_capturing('version', bogus: true) }
        .to raise_error(ArgumentError, /Unknown options: bogus/)
    end
  end

  describe '#command_streaming' do
    let(:context) { described_class.new }
    let(:command_line_double) { instance_double(Git::CommandLine::Streaming) }
    let(:result) { command_result('') }

    before do
      allow(context).to receive(:command_line_streaming).and_return(command_line_double)
      allow(Git::Base).to receive_message_chain(:config, :timeout).and_return(nil)
    end

    it 'delegates to command_line_streaming.run' do
      expect(command_line_double).to receive(:run)
        .with('cat-file', '--batch', hash_including(raise_on_failure: true, timeout: nil))
        .and_return(result)
      context.command_streaming('cat-file', '--batch')
    end

    it 'raises ArgumentError for unknown option keys' do
      expect { context.command_streaming('cat-file', bogus: true) }
        .to raise_error(ArgumentError, /Unknown options: bogus/)
    end
  end

  describe '#git_version' do
    let(:context) { described_class.new }
    let(:version_command_double) { instance_double(Git::Commands::Version) }

    before do
      allow(Git::Commands::Version).to receive(:new).with(context).and_return(version_command_double)
    end

    it 'calls Git::Commands::Version and returns a parsed Git::Version' do
      allow(version_command_double).to receive(:call).and_return(command_result('git version 2.40.0'))
      expect(context.git_version).to be_a(Git::Version)
      expect(context.git_version.to_s).to eq('2.40.0')
    end

    it 'memoizes the result per instance' do
      allow(version_command_double).to receive(:call).once.and_return(command_result('git version 2.40.0'))
      context.git_version
      context.git_version
    end

    it 'raises Git::Error with a helpful message when the output cannot be parsed' do
      allow(version_command_double).to receive(:call).and_return(command_result('not a version string'))
      expect { context.git_version }
        .to raise_error(Git::Error, /Unable to parse git version/)
    end
  end
end
