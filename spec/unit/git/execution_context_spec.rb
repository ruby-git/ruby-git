# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::ExecutionContext do
  describe '#initialize' do
    it 'raises NotImplementedError when instantiated directly' do
      expect { described_class.new }
        .to raise_error(NotImplementedError, /abstract base class/)
    end
  end

  describe '#git_dir' do
    it 'returns nil for a Global context' do
      expect(Git::ExecutionContext::Global.new.git_dir).to be_nil
    end
  end

  describe '#git_work_dir' do
    it 'returns nil for a Global context' do
      expect(Git::ExecutionContext::Global.new.git_work_dir).to be_nil
    end
  end

  describe '#git_index_file' do
    it 'returns nil for a Global context' do
      expect(Git::ExecutionContext::Global.new.git_index_file).to be_nil
    end
  end

  describe '#git_ssh' do
    context 'when using global config (default)' do
      it 'delegates to Git::Config.instance' do
        allow(Git::Config.instance).to receive(:git_ssh).and_return('/configured/ssh')
        expect(Git::ExecutionContext::Global.new.git_ssh).to eq('/configured/ssh')
      end
    end

    context 'when nil is passed explicitly' do
      it 'returns nil' do
        expect(Git::ExecutionContext::Global.new(git_ssh: nil).git_ssh).to be_nil
      end
    end

    context 'when a literal path is provided' do
      it 'returns the provided path' do
        expect(Git::ExecutionContext::Global.new(git_ssh: '/usr/bin/ssh').git_ssh).to eq('/usr/bin/ssh')
      end
    end
  end

  describe '#binary_path' do
    context 'when using global config (default)' do
      it 'delegates to Git::Config.instance' do
        allow(Git::Config.instance).to receive(:binary_path).and_return('/configured/git')
        expect(Git::ExecutionContext::Global.new.binary_path).to eq('/configured/git')
      end
    end

    context 'when an explicit path is provided' do
      it 'returns the provided path' do
        expect(Git::ExecutionContext::Global.new(binary_path: '/usr/local/bin/git').binary_path).to(
          eq('/usr/local/bin/git')
        )
      end
    end

    context 'when nil is passed explicitly' do
      it 'raises ArgumentError' do
        expect { Git::ExecutionContext::Global.new(binary_path: nil) }.to raise_error(ArgumentError, /binary_path/)
      end
    end
  end

  describe '#command_capturing' do
    let(:context) { Git::ExecutionContext::Global.new }
    let(:command_line_double) { instance_double(Git::CommandLine::Capturing) }
    let(:result) { command_result('output') }

    before do
      allow(context).to receive(:command_line_capturing).and_return(command_line_double)
      allow(Git::Config.instance).to receive(:timeout).and_return(nil)
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

    context 'when building the CommandLine instance (env and global opts)' do
      before do
        allow(context).to receive(:command_line_capturing).and_call_original
        allow(Git::CommandLine::Capturing).to receive(:new).and_return(command_line_double)
        allow(command_line_double).to receive(:run).and_return(result)
      end

      it 'passes GIT_EDITOR=true and LC_ALL=en_US.UTF-8 in the env hash' do
        context.command_capturing('version')
        expect(Git::CommandLine::Capturing).to have_received(:new).with(
          hash_including('GIT_EDITOR' => 'true', 'LC_ALL' => 'en_US.UTF-8'),
          anything, anything, anything
        )
      end

      it 'passes the resolved binary_path as the second argument' do
        allow(Git::Config.instance).to receive(:binary_path).and_return('configured-git')
        context.command_capturing('version')
        expect(Git::CommandLine::Capturing).to have_received(:new).with(
          anything, 'configured-git', anything, anything
        )
      end

      it 'includes the static global opts and excludes --git-dir for a Global context' do
        context.command_capturing('version')
        expect(Git::CommandLine::Capturing).to have_received(:new).with(
          anything,
          anything,
          satisfy { |opts| opts.include?('-c') && opts.none? { |o| o.start_with?('--git-dir') } },
          anything
        )
      end
    end
  end

  describe '#command_streaming' do
    let(:context) { Git::ExecutionContext::Global.new }
    let(:command_line_double) { instance_double(Git::CommandLine::Streaming) }
    let(:result) { command_result('') }

    before do
      allow(context).to receive(:command_line_streaming).and_return(command_line_double)
      allow(Git::Config.instance).to receive(:timeout).and_return(nil)
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

    context 'when building the CommandLine instance (env and resolved binary_path)' do
      before do
        allow(context).to receive(:command_line_streaming).and_call_original
        allow(Git::CommandLine::Streaming).to receive(:new).and_return(command_line_double)
        allow(command_line_double).to receive(:run).and_return(result)
      end

      it 'creates a Git::CommandLine::Streaming with env overrides and resolved binary_path' do
        context.command_streaming('version')

        expect(Git::CommandLine::Streaming).to have_received(:new).with(
          hash_including('GIT_EDITOR' => 'true', 'LC_ALL' => 'en_US.UTF-8'),
          context.binary_path,
          anything,
          anything
        )
      end
    end
  end

  describe '#git_version' do
    let(:context) { Git::ExecutionContext::Global.new }
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

    it 'raises Git::UnexpectedResultError when the output cannot be parsed' do
      allow(version_command_double).to receive(:call).and_return(command_result('not a version string'))
      expect { context.git_version }
        .to raise_error(Git::UnexpectedResultError, /Invalid version/)
    end
  end
end
