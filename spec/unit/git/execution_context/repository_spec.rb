# frozen_string_literal: true

require 'spec_helper'
require 'git/execution_context/repository'

RSpec.describe Git::ExecutionContext::Repository do
  let(:git_dir) { '/repo/.git' }
  let(:git_work_dir) { '/repo' }
  let(:git_index_file) { '/repo/.git/index' }

  describe 'inheritance' do
    it 'is a Git::ExecutionContext' do
      context = described_class.new(git_dir: git_dir)
      expect(context).to be_a(Git::ExecutionContext)
    end
  end

  describe '#initialize' do
    it 'stores all provided keyword arguments as attributes' do
      instance = described_class.new(
        git_dir: git_dir,
        git_work_dir: git_work_dir,
        git_index_file: git_index_file,
        git_ssh: '/usr/bin/ssh',
        binary_path: '/usr/local/bin/git'
      )
      expect(instance).to have_attributes(
        git_dir: git_dir,
        git_work_dir: git_work_dir,
        git_index_file: git_index_file,
        git_ssh: '/usr/bin/ssh',
        binary_path: '/usr/local/bin/git'
      )
    end
  end

  describe '#dup_with' do
    let(:logger) { Logger.new(nil) }

    let(:original) do
      described_class.new(
        git_dir: git_dir,
        git_work_dir: git_work_dir,
        git_index_file: git_index_file,
        binary_path: :use_global_config,
        git_ssh: :use_global_config,
        logger: logger
      )
    end

    it 'returns a new instance of the same class' do
      expect(original.dup_with).to be_a(described_class)
    end

    it 'returns a different object' do
      expect(original.dup_with).not_to be(original)
    end

    it 'copies all path attributes' do
      duped = original.dup_with
      expect(duped).to have_attributes(
        git_dir: git_dir,
        git_work_dir: git_work_dir,
        git_index_file: git_index_file
      )
    end

    it 'preserves the logger instance' do
      expect(original.dup_with.logger).to be(logger)
    end

    it 'preserves the :use_global_config sentinel for binary_path' do
      duped = original.dup_with
      allow(Git::Config.instance).to receive(:binary_path).and_return('/new/git')
      expect(duped.binary_path).to eq('/new/git')
    end

    it 'preserves the :use_global_config sentinel for git_ssh' do
      duped = original.dup_with
      allow(Git::Config.instance).to receive(:git_ssh).and_return('/new/wrapper')
      expect(duped.git_ssh).to eq('/new/wrapper')
    end

    it 'applies provided overrides' do
      duped = original.dup_with(git_index_file: '/new/index')
      expect(duped.git_index_file).to eq('/new/index')
      expect(duped.git_dir).to eq(git_dir)
    end

    it 'does not mutate the original' do
      original.dup_with(git_index_file: '/new/index')
      expect(original.git_index_file).to eq(git_index_file)
    end
  end

  describe 'binary_path resolution' do
    context 'with :use_global_config (default)' do
      let(:context) { described_class.new(git_dir: git_dir) }

      it 'delegates to Git::Config.instance.binary_path' do
        allow(Git::Config.instance).to receive(:binary_path).and_return('/global/git')
        expect(context.binary_path).to eq('/global/git')
      end
    end

    context 'with a literal binary_path' do
      let(:context) { described_class.new(git_dir: git_dir, binary_path: '/usr/local/bin/git') }

      it 'returns the provided path' do
        expect(context.binary_path).to eq('/usr/local/bin/git')
      end
    end
  end

  describe 'accessor methods' do
    let(:context) do
      described_class.new(
        git_dir: git_dir,
        git_work_dir: git_work_dir,
        git_index_file: git_index_file
      )
    end

    it 'exposes git_dir' do
      expect(context.git_dir).to eq(git_dir)
    end

    it 'exposes git_work_dir' do
      expect(context.git_work_dir).to eq(git_work_dir)
    end

    it 'exposes git_index_file' do
      expect(context.git_index_file).to eq(git_index_file)
    end
  end

  describe 'git_ssh resolution' do
    context 'with a literal git_ssh path' do
      let(:context) { described_class.new(git_dir: git_dir, git_ssh: '/usr/bin/ssh') }

      it 'returns the provided path' do
        expect(context.git_ssh).to eq('/usr/bin/ssh')
      end
    end

    context 'with :use_global_config (default)' do
      let(:context) { described_class.new(git_dir: git_dir) }

      it 'delegates to Git::Config.instance.git_ssh' do
        allow(Git::Config.instance).to receive(:git_ssh).and_return('/configured/ssh')
        expect(context.git_ssh).to eq('/configured/ssh')
      end
    end

    context 'with nil git_ssh explicitly passed' do
      let(:context) { described_class.new(git_dir: git_dir, git_ssh: nil) }

      it 'returns nil' do
        expect(context.git_ssh).to be_nil
      end
    end
  end

  describe '.from_hash' do
    let(:hash) do
      {
        repository: git_dir,
        working_directory: git_work_dir,
        index: git_index_file
      }
    end

    subject(:context) { described_class.from_hash(hash) }

    it 'returns a Git::ExecutionContext::Repository' do
      expect(context).to be_a(described_class)
    end

    it 'extracts git_dir from hash[:repository]' do
      expect(context.git_dir).to eq(git_dir)
    end

    it 'extracts git_work_dir from hash[:working_directory]' do
      expect(context.git_work_dir).to eq(git_work_dir)
    end

    it 'extracts git_index_file from hash[:index]' do
      expect(context.git_index_file).to eq(git_index_file)
    end

    it 'defaults git_ssh to :use_global_config when :git_ssh is absent' do
      allow(Git::Config.instance).to receive(:git_ssh).and_return('/global/ssh')
      expect(context.git_ssh).to eq('/global/ssh')
    end

    it 'uses the provided git_ssh when :git_ssh is present in hash' do
      hash[:git_ssh] = '/custom/ssh'
      expect(context.git_ssh).to eq('/custom/ssh')
    end

    it 'defaults binary_path to :use_global_config when :binary_path is absent' do
      allow(Git::Config.instance).to receive(:binary_path).and_return('/global/git')
      expect(context.binary_path).to eq('/global/git')
    end

    it 'uses the provided binary_path when :binary_path is present in hash' do
      hash[:binary_path] = '/custom/git'
      expect(context.binary_path).to eq('/custom/git')
    end
  end

  describe '#command_capturing' do
    let(:context) { described_class.new(git_dir: git_dir, git_work_dir: git_work_dir) }
    let(:command_line_double) { instance_double(Git::CommandLine::Capturing) }
    let(:result) { command_result('output') }

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

    it 'passes raise_on_failure: false when specified' do
      expect(command_line_double).to receive(:run)
        .with('status', hash_including(raise_on_failure: false))
        .and_return(result)
      context.command_capturing('status', raise_on_failure: false)
    end

    it 'applies the global timeout when no timeout is specified' do
      allow(Git::Config.instance).to receive(:timeout).and_return(30)
      expect(command_line_double).to receive(:run)
        .with('status', hash_including(timeout: 30))
        .and_return(result)
      context.command_capturing('status')
    end

    it 'raises ArgumentError for unknown options' do
      expect { context.command_capturing('version', unknown_opt: true) }
        .to raise_error(ArgumentError, /Unknown options: unknown_opt/)
    end

    context 'when building the CommandLine instance (env and global opts)' do
      before do
        allow(context).to receive(:command_line_capturing).and_call_original
        allow(Git::CommandLine::Capturing).to receive(:new).and_return(command_line_double)
        allow(command_line_double).to receive(:run).and_return(result)
      end

      it 'passes GIT_DIR and GIT_WORK_TREE in the env hash' do
        context.command_capturing('version')
        expect(Git::CommandLine::Capturing).to have_received(:new).with(
          hash_including('GIT_DIR' => git_dir, 'GIT_WORK_TREE' => git_work_dir),
          anything, anything, anything
        )
      end

      it 'passes GIT_EDITOR=true and LC_ALL=en_US.UTF-8 in the env hash' do
        context.command_capturing('version')
        expect(Git::CommandLine::Capturing).to have_received(:new).with(
          hash_including('GIT_EDITOR' => 'true', 'LC_ALL' => 'en_US.UTF-8'),
          anything, anything, anything
        )
      end

      it 'includes --git-dir and --work-tree in global opts' do
        context.command_capturing('version')
        expect(Git::CommandLine::Capturing).to have_received(:new).with(
          anything,
          anything,
          include("--git-dir=#{git_dir}", "--work-tree=#{git_work_dir}"),
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
    let(:context) { described_class.new(git_dir: git_dir, git_work_dir: git_work_dir) }
    let(:command_line_double) { instance_double(Git::CommandLine::Streaming) }
    let(:result) { command_result('') }
    let(:out_io) { StringIO.new }

    before do
      allow(context).to receive(:command_line_streaming).and_return(command_line_double)
      allow(Git::Config.instance).to receive(:timeout).and_return(nil)
    end

    it 'delegates to command_line_streaming.run' do
      expect(command_line_double).to receive(:run)
        .with('cat-file', '--batch', hash_including(out: out_io, raise_on_failure: true, timeout: nil))
        .and_return(result)
      context.command_streaming('cat-file', '--batch', out: out_io)
    end

    it 'raises ArgumentError for unknown options' do
      expect { context.command_streaming('cat-file', unknown_opt: true) }
        .to raise_error(ArgumentError, /Unknown options: unknown_opt/)
    end
  end
end
