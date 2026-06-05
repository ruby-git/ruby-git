# frozen_string_literal: true

require 'spec_helper'
require 'git/execution_context/global'

RSpec.describe Git::ExecutionContext::Global do
  describe 'inheritance' do
    it 'is a Git::ExecutionContext' do
      expect(described_class.new).to be_a(Git::ExecutionContext)
    end
  end

  describe '#initialize' do
    it 'exposes default attribute values using Git::Config.instance' do
      allow(Git::Config.instance).to receive(:binary_path).and_return('git')
      allow(Git::Config.instance).to receive(:git_ssh).and_return(nil)
      expect(described_class.new).to have_attributes(
        binary_path: 'git',
        git_ssh: nil,
        git_dir: nil,
        git_work_dir: nil,
        git_index_file: nil
      )
    end
  end

  describe 'binary_path resolution' do
    it 'delegates to Git::Config.instance by default' do
      allow(Git::Config.instance).to receive(:binary_path).and_return('/global/git')
      expect(described_class.new.binary_path).to eq('/global/git')
    end

    it 'returns an explicit path when provided' do
      expect(described_class.new(binary_path: '/usr/local/bin/git').binary_path).to eq('/usr/local/bin/git')
    end

    it 'raises ArgumentError when explicitly passed nil' do
      expect { described_class.new(binary_path: nil) }.to raise_error(ArgumentError, /binary_path/)
    end
  end

  describe 'accessor methods' do
    let(:context) { described_class.new(git_ssh: nil) }

    it 'returns nil for git_dir' do
      expect(context.git_dir).to be_nil
    end

    it 'returns nil for git_work_dir' do
      expect(context.git_work_dir).to be_nil
    end

    it 'returns nil for git_index_file' do
      expect(context.git_index_file).to be_nil
    end
  end

  describe 'git_ssh resolution' do
    it 'delegates to Git::Config.instance by default' do
      allow(Git::Config.instance).to receive(:git_ssh).and_return('/global/ssh')
      expect(described_class.new.git_ssh).to eq('/global/ssh')
    end

    it 'returns nil when explicitly passed nil' do
      expect(described_class.new(git_ssh: nil).git_ssh).to be_nil
    end

    it 'returns a literal path when provided' do
      expect(described_class.new(git_ssh: '/usr/bin/ssh').git_ssh).to eq('/usr/bin/ssh')
    end
  end

  describe '#command_capturing' do
    let(:context) { described_class.new }
    let(:command_line_double) { instance_double(Git::CommandLine::Capturing) }
    let(:result) { command_result('git version 2.40.0') }

    before do
      allow(context).to receive(:command_line_capturing).and_return(command_line_double)
      allow(Git::Config.instance).to receive(:timeout).and_return(nil)
    end

    it 'delegates to command_line_capturing.run' do
      expect(command_line_double).to receive(:run)
        .with('version', hash_including(raise_on_failure: true, normalize: true))
        .and_return(result)
      context.command_capturing('version')
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

      it 'does not include --git-dir in global opts (no repository scope)' do
        context.command_capturing('version')
        expect(Git::CommandLine::Capturing).to have_received(:new).with(
          anything,
          anything,
          satisfy { |opts| opts.none? { |o| o.start_with?('--git-dir') } },
          anything
        )
      end

      it 'includes the static global opts' do
        context.command_capturing('version')
        expect(Git::CommandLine::Capturing).to have_received(:new).with(
          anything,
          anything,
          include('-c', 'core.quotePath=true'),
          anything
        )
      end
    end
  end

  describe '#command_streaming' do
    let(:context) { described_class.new }
    let(:command_line_double) { instance_double(Git::CommandLine::Streaming) }
    let(:result) { command_result('') }
    let(:out_io) { StringIO.new }

    before do
      allow(context).to receive(:command_line_streaming).and_return(command_line_double)
      allow(Git::Config.instance).to receive(:timeout).and_return(nil)
    end

    it 'delegates to command_line_streaming.run' do
      expect(command_line_double).to receive(:run)
        .with('clone', hash_including(out: out_io, raise_on_failure: true, timeout: nil))
        .and_return(result)
      context.command_streaming('clone', out: out_io)
    end
  end
end
