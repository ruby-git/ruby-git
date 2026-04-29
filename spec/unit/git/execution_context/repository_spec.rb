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
    it 'accepts git_dir as a keyword argument' do
      expect { described_class.new(git_dir: git_dir) }.not_to raise_error
    end

    it 'accepts all repository path options' do
      expect do
        described_class.new(
          git_dir: git_dir,
          git_work_dir: git_work_dir,
          git_index_file: git_index_file,
          git_ssh: '/usr/bin/ssh',
          binary_path: '/usr/local/bin/git',
          logger: nil
        )
      end.not_to raise_error
    end
  end

  describe 'binary_path resolution' do
    context 'with :use_global_config (default)' do
      let(:context) { described_class.new(git_dir: git_dir) }

      it 'delegates to Git::Base.config.binary_path' do
        allow(Git::Base).to receive_message_chain(:config, :binary_path).and_return('/global/git')
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

  describe 'env_overrides (via #send)' do
    let(:context) do
      described_class.new(
        git_dir: git_dir,
        git_work_dir: git_work_dir,
        git_index_file: git_index_file
      )
    end

    before do
      allow(Git::Base).to receive_message_chain(:config, :git_ssh).and_return(nil)
    end

    it 'sets GIT_DIR to git_dir' do
      expect(context.send(:env_overrides)['GIT_DIR']).to eq(git_dir)
    end

    it 'sets GIT_WORK_TREE to git_work_dir' do
      expect(context.send(:env_overrides)['GIT_WORK_TREE']).to eq(git_work_dir)
    end

    it 'sets GIT_INDEX_FILE to git_index_file' do
      expect(context.send(:env_overrides)['GIT_INDEX_FILE']).to eq(git_index_file)
    end

    it 'sets GIT_EDITOR to "true" (no-op editor)' do
      expect(context.send(:env_overrides)['GIT_EDITOR']).to eq('true')
    end

    it 'sets LC_ALL to "en_US.UTF-8"' do
      expect(context.send(:env_overrides)['LC_ALL']).to eq('en_US.UTF-8')
    end

    it 'merges caller-supplied additional overrides' do
      env = context.send(:env_overrides, 'GIT_TRACE' => '1')
      expect(env['GIT_TRACE']).to eq('1')
    end

    it 'allows unsetting an env var by passing nil' do
      env = context.send(:env_overrides, 'GIT_INDEX_FILE' => nil)
      expect(env['GIT_INDEX_FILE']).to be_nil
    end
  end

  describe 'global_opts (via #send)' do
    context 'with git_dir and git_work_dir set' do
      let(:context) do
        described_class.new(git_dir: git_dir, git_work_dir: git_work_dir)
      end

      it 'includes --git-dir=<path>' do
        expect(context.send(:global_opts)).to include("--git-dir=#{git_dir}")
      end

      it 'includes --work-tree=<path>' do
        expect(context.send(:global_opts)).to include("--work-tree=#{git_work_dir}")
      end

      it 'includes the static global opts' do
        expect(context.send(:global_opts)).to include('-c', 'core.quotePath=true')
      end
    end

    context 'without git_work_dir' do
      let(:context) { described_class.new(git_dir: git_dir) }

      it 'does not include --work-tree' do
        expect(context.send(:global_opts).grep(/\A--work-tree/)).to be_empty
      end
    end

    context 'without git_dir' do
      let(:context) { described_class.new(git_dir: nil) }

      it 'does not include --git-dir' do
        expect(context.send(:global_opts).grep(/\A--git-dir/)).to be_empty
      end
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

      it 'delegates to Git::Base.config.git_ssh' do
        allow(Git::Base).to receive_message_chain(:config, :git_ssh).and_return('/configured/ssh')
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

  describe '.from_base' do
    let(:repo_double) { double('repo', to_s: git_dir) }
    let(:index_double) { double('index', to_s: git_index_file) }
    let(:dir_double) { double('dir', to_s: git_work_dir) }
    let(:base) do
      double('Git::Base',
             repo: repo_double, index: index_double, dir: dir_double,
             git_ssh: nil, binary_path: :use_global_config)
    end

    subject(:context) { described_class.from_base(base) }

    it 'returns a Git::ExecutionContext::Repository' do
      expect(context).to be_a(described_class)
    end

    it 'extracts git_dir from base.repo.to_s' do
      expect(context.git_dir).to eq(git_dir)
    end

    it 'extracts git_work_dir from base.dir.to_s' do
      expect(context.git_work_dir).to eq(git_work_dir)
    end

    it 'extracts git_index_file from base.index.to_s' do
      expect(context.git_index_file).to eq(git_index_file)
    end

    context 'when base.binary_path is an explicit path' do
      let(:base) do
        double('Git::Base',
               repo: repo_double, index: index_double, dir: dir_double,
               git_ssh: nil, binary_path: '/custom/git')
      end

      it 'forwards binary_path to the context' do
        expect(context.binary_path).to eq('/custom/git')
      end
    end

    context 'when base.binary_path is :use_global_config (default)' do
      it 'delegates binary_path resolution to Git::Base.config' do
        allow(Git::Base).to receive_message_chain(:config, :binary_path).and_return('/global/git')
        expect(context.binary_path).to eq('/global/git')
      end
    end

    context 'when base.dir is nil' do
      let(:dir_double) { nil }

      it 'sets git_work_dir to nil' do
        expect(context.git_work_dir).to be_nil
      end
    end

    context 'when base.index is nil' do
      let(:index_double) { nil }

      it 'sets git_index_file to nil' do
        expect(context.git_index_file).to be_nil
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
      allow(Git::Base).to receive_message_chain(:config, :git_ssh).and_return('/global/ssh')
      expect(context.git_ssh).to eq('/global/ssh')
    end

    it 'uses the provided git_ssh when :git_ssh is present in hash' do
      hash[:git_ssh] = '/custom/ssh'
      expect(context.git_ssh).to eq('/custom/ssh')
    end

    it 'defaults binary_path to :use_global_config when :binary_path is absent' do
      allow(Git::Base).to receive_message_chain(:config, :binary_path).and_return('/global/git')
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
      allow(Git::Base).to receive_message_chain(:config, :timeout).and_return(nil)
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
      allow(Git::Base).to receive_message_chain(:config, :timeout).and_return(30)
      expect(command_line_double).to receive(:run)
        .with('status', hash_including(timeout: 30))
        .and_return(result)
      context.command_capturing('status')
    end

    it 'raises ArgumentError for unknown options' do
      expect { context.command_capturing('version', unknown_opt: true) }
        .to raise_error(ArgumentError, /Unknown options: unknown_opt/)
    end
  end

  describe '#command_streaming' do
    let(:context) { described_class.new(git_dir: git_dir, git_work_dir: git_work_dir) }
    let(:command_line_double) { instance_double(Git::CommandLine::Streaming) }
    let(:result) { command_result('') }
    let(:out_io) { StringIO.new }

    before do
      allow(context).to receive(:command_line_streaming).and_return(command_line_double)
      allow(Git::Base).to receive_message_chain(:config, :timeout).and_return(nil)
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
