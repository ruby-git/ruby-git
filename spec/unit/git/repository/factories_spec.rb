# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'

RSpec.describe Git::Repository::Factories do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:host) { Module.new { extend Git::Repository::Factories } }

  describe '.open' do
    subject(:repository) { host.open(working_dir, options) }

    let(:working_dir) { '/repo' }
    let(:options) { {} }
    let(:resolved_paths) do
      { working_directory: '/repo', repository: '/repo/.git', index: '/repo/.git/index' }
    end

    before do
      allow(Dir).to receive(:exist?).with(working_dir).and_return(true)
      allow(Git::Repository::PathResolver).to(
        receive(:root_of_worktree)
          .with(working_dir, binary_path: :use_global_config, git_ssh: :use_global_config)
          .and_return(working_dir)
      )
      allow(Git::Repository::PathResolver).to receive(:resolve_paths).and_return(resolved_paths)
      allow(Git::ExecutionContext::Repository).to receive(:from_hash).and_return(execution_context)
    end

    it 'returns a Git::Repository' do
      expect(repository).to be_a(Git::Repository)
    end

    it 'detects the root of the worktree when no repository option is given' do
      repository
      expect(Git::Repository::PathResolver).to(
        have_received(:root_of_worktree)
          .with(working_dir, binary_path: :use_global_config, git_ssh: :use_global_config)
      )
    end

    it 'resolves the paths from the detected working directory' do
      repository
      expect(Git::Repository::PathResolver).to(
        have_received(:resolve_paths).with(working_directory: working_dir, repository: nil, index: nil)
      )
    end

    it 'builds the execution context from the merged options and resolved paths' do
      repository
      expect(Git::ExecutionContext::Repository).to(
        have_received(:from_hash).with(options.merge(resolved_paths), logger: nil)
      )
    end

    context 'when binary_path is given' do
      let(:options) { { binary_path: '/custom/git' } }

      it 'forwards binary_path to root_of_worktree' do
        expect(Git::Repository::PathResolver).to(
          receive(:root_of_worktree)
            .with(working_dir, binary_path: '/custom/git', git_ssh: :use_global_config)
            .and_return(working_dir)
        )
        repository
      end
    end

    context 'when git_ssh is given' do
      let(:options) { { git_ssh: '/custom/ssh' } }

      it 'forwards git_ssh to root_of_worktree' do
        expect(Git::Repository::PathResolver).to(
          receive(:root_of_worktree)
            .with(working_dir, binary_path: :use_global_config, git_ssh: '/custom/ssh')
            .and_return(working_dir)
        )
        repository
      end
    end

    context 'when git_ssh is nil (explicitly unset)' do
      let(:options) { { git_ssh: nil } }

      before do
        allow(Git::Repository::PathResolver).to(
          receive(:root_of_worktree)
            .with(working_dir, binary_path: :use_global_config, git_ssh: nil)
            .and_return(working_dir)
        )
      end

      it 'forwards nil git_ssh to root_of_worktree' do
        repository
        expect(Git::Repository::PathResolver).to(
          have_received(:root_of_worktree)
            .with(working_dir, binary_path: :use_global_config, git_ssh: nil)
        )
      end
    end

    context 'when an explicit repository option is given' do
      let(:options) { { repository: '/custom/.git' } }

      it 'does not auto-detect the root of the worktree' do
        expect(Git::Repository::PathResolver).not_to receive(:root_of_worktree)
        repository
      end

      it 'forwards the repository and index options to resolve_paths' do
        repository
        expect(Git::Repository::PathResolver).to(
          have_received(:resolve_paths).with(working_directory: working_dir, repository: '/custom/.git', index: nil)
        )
      end
    end

    context 'when a logger is given' do
      let(:options) { { log: instance_double(Logger) } }

      it 'forwards the logger to the execution context' do
        repository
        expect(Git::ExecutionContext::Repository).to(
          have_received(:from_hash).with(anything, logger: options[:log])
        )
      end
    end

    context 'when the working directory is not a directory' do
      before { allow(Dir).to receive(:exist?).with(working_dir).and_return(false) }

      it 'raises ArgumentError' do
        expect { repository }.to raise_error(ArgumentError, /is not a directory/)
      end
    end
  end

  describe '.clone' do
    subject(:repository) { host.clone(repository_url, directory, options) }

    let(:repository_url) { 'https://github.com/ruby-git/ruby-git.git' }
    let(:directory) { nil }
    let(:options) { {} }
    let(:clone_command) { instance_double(Git::Commands::Clone) }
    let(:global_context) { instance_double(Git::ExecutionContext::Global) }
    let(:clone_stderr) { "Cloning into 'ruby-git'...\n" }
    let(:clone_result) { command_result('', stderr: clone_stderr) }
    let(:resolved_paths) do
      { working_directory: 'ruby-git', repository: 'ruby-git/.git', index: 'ruby-git/.git/index' }
    end

    before do
      allow(Git::ExecutionContext::Global).to receive(:new).and_return(global_context)
      allow(Git::Commands::Clone).to receive(:new).with(global_context).and_return(clone_command)
      allow(clone_command).to receive(:call).and_return(clone_result)
      allow(Git::Repository::PathResolver).to receive(:resolve_paths).and_return(resolved_paths)
      allow(Git::ExecutionContext::Repository).to receive(:from_hash).and_return(execution_context)
    end

    it 'returns a Git::Repository' do
      expect(repository).to be_a(Git::Repository)
    end

    it 'uses ExecutionContext::Global (not Git::Lib) for the clone operation' do
      expect(Git::ExecutionContext::Global).to receive(:new).and_return(global_context)
      repository
    end

    it 'delegates to Commands::Clone#call with the repository URL' do
      repository
      expect(clone_command).to have_received(:call).with(repository_url, nil)
    end

    context 'when a directory argument is given' do
      let(:directory) { 'my-repo' }

      it 'forwards the directory to Commands::Clone#call' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, 'my-repo')
      end
    end

    it 'resolves paths using the working directory for non-bare clones' do
      repository
      expect(Git::Repository::PathResolver).to(
        have_received(:resolve_paths).with(working_directory: 'ruby-git', index: nil)
      )
    end

    context 'when cloning a bare repository via :bare option' do
      let(:options) { { bare: true } }
      let(:clone_stderr) { "Cloning into bare repository 'ruby-git.git'...\n" }

      it 'resolves paths as a bare repository' do
        repository
        expect(Git::Repository::PathResolver).to(
          have_received(:resolve_paths).with(repository: 'ruby-git.git', bare: true, index: nil)
        )
      end
    end

    context 'when cloning with :mirror option' do
      let(:options) { { mirror: true } }
      let(:clone_stderr) { "Cloning into bare repository 'ruby-git.git'...\n" }

      it 'resolves paths as a bare repository' do
        repository
        expect(Git::Repository::PathResolver).to(
          have_received(:resolve_paths).with(repository: 'ruby-git.git', bare: true, index: nil)
        )
      end
    end

    context 'when :chdir is given' do
      let(:options) { { chdir: '/output' } }

      it 'prefixes the clone directory with chdir' do
        repository
        expect(Git::Repository::PathResolver).to(
          have_received(:resolve_paths).with(working_directory: '/output/ruby-git', index: nil)
        )
      end

      it 'forwards :chdir to Commands::Clone' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil, chdir: '/output')
      end

      context 'when the reported clone directory is absolute' do
        let(:clone_stderr) { "Cloning into '/abs/path'...\n" }

        it 'uses the absolute path as-is (ignores :chdir)' do
          repository
          expect(Git::Repository::PathResolver).to(
            have_received(:resolve_paths).with(working_directory: '/abs/path', index: nil)
          )
        end
      end
    end

    context 'with :log option' do
      let(:log) { instance_double(Logger) }
      let(:options) { { log: log } }

      it 'uses the logger in the execution context' do
        expect(Git::ExecutionContext::Global).to receive(:new).with(
          binary_path: :use_global_config,
          git_ssh: :use_global_config,
          logger: log
        ).and_return(global_context)
        repository
      end

      it 'does not forward :log to Commands::Clone' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil)
      end
    end

    context 'with :git_ssh option' do
      let(:options) { { git_ssh: '/custom/ssh' } }

      it 'uses git_ssh in the execution context' do
        expect(Git::ExecutionContext::Global).to receive(:new).with(
          binary_path: :use_global_config,
          git_ssh: '/custom/ssh',
          logger: nil
        ).and_return(global_context)
        repository
      end

      it 'does not forward :git_ssh to Commands::Clone' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil)
      end
    end

    context 'with :binary_path option' do
      let(:options) { { binary_path: '/custom/git' } }

      it 'uses binary_path in the execution context' do
        expect(Git::ExecutionContext::Global).to receive(:new).with(
          binary_path: '/custom/git',
          git_ssh: :use_global_config,
          logger: nil
        ).and_return(global_context)
        repository
      end

      it 'does not forward :binary_path to Commands::Clone' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil)
      end
    end

    context 'with :index option' do
      let(:options) { { index: '/custom/index' } }
      let(:resolved_with_index) do
        { working_directory: 'ruby-git', repository: 'ruby-git/.git', index: '/custom/index' }
      end

      before do
        allow(Git::Repository::PathResolver).to receive(:resolve_paths)
          .with(working_directory: 'ruby-git', index: '/custom/index')
          .and_return(resolved_with_index)
      end

      it 'forwards :index to path resolution' do
        repository
        expect(Git::Repository::PathResolver).to(
          have_received(:resolve_paths).with(working_directory: 'ruby-git', index: '/custom/index')
        )
      end

      it 'does not forward :index to Commands::Clone' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil)
      end
    end

    context 'with :repository option' do
      let(:options) { { repository: '/custom/.git' } }

      it 'maps :repository to :separate_git_dir for Commands::Clone' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil, separate_git_dir: '/custom/.git')
      end
    end

    context 'with :repository option set to nil' do
      let(:options) { { repository: nil } }

      it 'does not pass :separate_git_dir to Commands::Clone' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil)
      end
    end

    context 'with deprecated :path option' do
      let(:options) { { path: '/output' } }

      it 'emits a deprecation warning' do
        expect(Git::Deprecation).to receive(:warn).with(/path.*deprecated/i)
        repository
      end

      it 'uses :path value as :chdir' do
        allow(Git::Deprecation).to receive(:warn)
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil, chdir: '/output')
      end

      context 'when Git::Deprecation is unavailable' do
        before { hide_const('Git::Deprecation') }

        it 'still uses :path value as :chdir' do
          repository
          expect(clone_command).to have_received(:call).with(repository_url, nil, chdir: '/output')
        end
      end
    end

    context 'with deprecated :recursive option' do
      let(:options) { { recursive: true } }

      it 'emits a deprecation warning' do
        expect(Git::Deprecation).to receive(:warn).with(/recursive.*deprecated/i)
        repository
      end

      it 'maps :recursive to :recurse_submodules' do
        allow(Git::Deprecation).to receive(:warn)
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil, recurse_submodules: true)
      end

      context 'when Git::Deprecation is unavailable' do
        before { hide_const('Git::Deprecation') }

        it 'still maps :recursive to :recurse_submodules' do
          repository
          expect(clone_command).to have_received(:call).with(repository_url, nil, recurse_submodules: true)
        end
      end
    end

    context 'with deprecated :remote option' do
      let(:options) { { remote: 'upstream' } }

      it 'emits a deprecation warning' do
        expect(Git::Deprecation).to receive(:warn).with(/remote.*deprecated/i)
        repository
      end

      it 'maps :remote to :origin' do
        allow(Git::Deprecation).to receive(:warn)
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil, origin: 'upstream')
      end

      context 'when Git::Deprecation is unavailable' do
        before { hide_const('Git::Deprecation') }

        it 'still maps :remote to :origin' do
          repository
          expect(clone_command).to have_received(:call).with(repository_url, nil, origin: 'upstream')
        end
      end
    end
  end

  describe '.init' do
    subject(:repository) { host.init(directory, options) }

    let(:directory) { '/new-repo' }
    let(:options) { {} }
    let(:init_command) { instance_double(Git::Commands::Init) }
    let(:global_context) { instance_double(Git::ExecutionContext::Global) }
    let(:init_result) { command_result('') }
    let(:resolved_paths) do
      { working_directory: '/new-repo', repository: '/new-repo/.git', index: '/new-repo/.git/index' }
    end

    before do
      allow(Git::ExecutionContext::Global).to receive(:new).and_return(global_context)
      allow(Git::Commands::Init).to receive(:new).with(global_context).and_return(init_command)
      allow(init_command).to receive(:call).and_return(init_result)
      allow(Dir).to receive(:exist?).with(directory).and_return(true)
      allow(Git::Repository::PathResolver).to(
        receive(:root_of_worktree).with(directory, any_args).and_return(directory)
      )
      allow(Git::Repository::PathResolver).to receive(:resolve_paths).and_return(resolved_paths)
      allow(Git::ExecutionContext::Repository).to receive(:from_hash).and_return(execution_context)
    end

    it 'returns a Git::Repository' do
      expect(repository).to be_a(Git::Repository)
    end

    it 'uses ExecutionContext::Global (not Git::Lib) for the init operation' do
      expect(Git::ExecutionContext::Global).to receive(:new).and_return(global_context)
      repository
    end

    it 'delegates to Commands::Init#call with the directory' do
      repository
      expect(init_command).to have_received(:call).with(directory)
    end

    context 'when :bare is given' do
      let(:options) { { bare: true } }
      let(:resolved_bare_paths) do
        { working_directory: nil, repository: '/new-repo', index: '/new-repo/index' }
      end

      before do
        allow(Git::Repository::PathResolver).to receive(:resolve_paths)
          .with(repository: directory, bare: true)
          .and_return(resolved_bare_paths)
      end

      it 'passes bare: true to Commands::Init' do
        repository
        expect(init_command).to have_received(:call).with(directory, bare: true)
      end

      it 'opens the result as a bare repository' do
        repository
        expect(Git::Repository::PathResolver).to(
          have_received(:resolve_paths).with(repository: directory, bare: true)
        )
      end
    end

    context 'when :initial_branch is given' do
      let(:options) { { initial_branch: 'main' } }

      it 'passes initial_branch to Commands::Init' do
        repository
        expect(init_command).to have_received(:call).with(directory, initial_branch: 'main')
      end
    end

    context 'when :repository option is given' do
      let(:options) { { repository: '/custom/git' } }
      let(:resolved_custom_paths) do
        { working_directory: '/new-repo', repository: '/custom/git', index: '/custom/git/index' }
      end

      before do
        allow(Git::Repository::PathResolver).to receive(:resolve_paths)
          .with(working_directory: directory, repository: '/custom/git', index: nil)
          .and_return(resolved_custom_paths)
      end

      it 'maps :repository to :separate_git_dir for Commands::Init' do
        repository
        expect(init_command).to have_received(:call).with(directory, separate_git_dir: '/custom/git')
      end
    end

    context 'when :separate_git_dir option is given' do
      let(:options) { { separate_git_dir: '/custom/git' } }
      let(:resolved_custom_paths) do
        { working_directory: '/new-repo', repository: '/custom/git', index: '/custom/git/index' }
      end

      before do
        allow(Git::Repository::PathResolver).to receive(:resolve_paths)
          .with(working_directory: directory, repository: '/custom/git', index: nil)
          .and_return(resolved_custom_paths)
      end

      it 'normalizes :separate_git_dir to :repository before forwarding to Commands::Init' do
        repository
        expect(init_command).to have_received(:call).with(directory, separate_git_dir: '/custom/git')
      end

      context 'when :repository key is present but nil' do
        let(:options) { { repository: nil, separate_git_dir: '/custom/git' } }

        it 'still normalizes :separate_git_dir to :repository before forwarding to Commands::Init' do
          repository
          expect(init_command).to have_received(:call).with(directory, separate_git_dir: '/custom/git')
        end
      end
    end

    context 'with :log option' do
      let(:log) { instance_double(Logger) }
      let(:options) { { log: log } }

      it 'uses the logger in the execution context' do
        expect(Git::ExecutionContext::Global).to receive(:new).with(
          binary_path: :use_global_config,
          git_ssh: :use_global_config,
          logger: log
        ).and_return(global_context)
        repository
      end
    end

    context 'with :git_ssh option' do
      let(:options) { { git_ssh: '/custom/ssh' } }

      before do
        allow(Git::Repository::PathResolver).to(
          receive(:root_of_worktree)
            .with(directory, binary_path: :use_global_config, git_ssh: '/custom/ssh')
            .and_return(directory)
        )
      end

      it 'uses git_ssh in the execution context' do
        expect(Git::ExecutionContext::Global).to receive(:new).with(
          binary_path: :use_global_config,
          git_ssh: '/custom/ssh',
          logger: nil
        ).and_return(global_context)
        repository
      end
    end

    context 'with :binary_path option' do
      let(:options) { { binary_path: '/custom/git' } }

      before do
        allow(Git::Repository::PathResolver).to(
          receive(:root_of_worktree)
            .with(directory, binary_path: '/custom/git', git_ssh: :use_global_config)
            .and_return(directory)
        )
      end

      it 'uses binary_path in the execution context' do
        expect(Git::ExecutionContext::Global).to receive(:new).with(
          binary_path: '/custom/git',
          git_ssh: :use_global_config,
          logger: nil
        ).and_return(global_context)
        repository
      end
    end
  end

  describe '.bare' do
    subject(:repository) { host.bare(git_dir, options) }

    let(:git_dir) { '/repo.git' }
    let(:options) { {} }
    let(:resolved_paths) do
      { working_directory: nil, repository: '/repo.git', index: '/repo.git/index' }
    end

    before do
      allow(Git::Repository::PathResolver).to receive(:resolve_paths).and_return(resolved_paths)
      allow(Git::ExecutionContext::Repository).to receive(:from_hash).and_return(execution_context)
    end

    it 'returns a Git::Repository' do
      expect(repository).to be_a(Git::Repository)
    end

    it 'resolves the paths as a bare repository' do
      repository
      expect(Git::Repository::PathResolver).to(
        have_received(:resolve_paths).with(repository: git_dir, bare: true)
      )
    end

    it 'builds the execution context from the merged options and resolved paths' do
      repository
      expect(Git::ExecutionContext::Repository).to(
        have_received(:from_hash).with(options.merge(resolved_paths), logger: nil)
      )
    end
  end
end
