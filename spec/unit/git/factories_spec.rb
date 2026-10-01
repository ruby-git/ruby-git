# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/factories'

RSpec.describe Git::Factories do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:host) { Module.new { extend Git::Factories } }

  describe '.open' do
    subject(:repository) { host.open(working_dir, options) }

    let(:working_dir) { '/repo' }
    let(:options) { {} }
    let(:resolved_paths) do
      { working_directory: '/repo', repository: '/repo/.git', index: '/repo/.git/index' }
    end

    before do
      allow(Dir).to receive(:exist?).with(working_dir).and_return(true)
      allow(Git::PathResolver).to(
        receive(:root_of_worktree)
          .with(working_dir, binary_path: :use_global_config, git_ssh: :use_global_config)
          .and_return(working_dir)
      )
      allow(Git::PathResolver).to receive(:resolve_paths).and_return(resolved_paths)
      allow(Git::ExecutionContext::Repository).to receive(:from_hash).and_return(execution_context)
    end

    it 'returns a Git::Repository' do
      expect(repository).to be_a(Git::Repository)
    end

    it 'detects the root of the worktree when no repository option is given' do
      repository
      expect(Git::PathResolver).to(
        have_received(:root_of_worktree)
          .with(working_dir, binary_path: :use_global_config, git_ssh: :use_global_config)
      )
    end

    it 'resolves the paths from the detected working directory' do
      repository
      expect(Git::PathResolver).to(
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
        expect(Git::PathResolver).to(
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
        expect(Git::PathResolver).to(
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
        allow(Git::PathResolver).to(
          receive(:root_of_worktree)
            .with(working_dir, binary_path: :use_global_config, git_ssh: nil)
            .and_return(working_dir)
        )
      end

      it 'forwards nil git_ssh to root_of_worktree' do
        repository
        expect(Git::PathResolver).to(
          have_received(:root_of_worktree)
            .with(working_dir, binary_path: :use_global_config, git_ssh: nil)
        )
      end
    end

    context 'when an explicit repository option is given' do
      let(:options) { { repository: '/custom/.git' } }

      it 'does not auto-detect the root of the worktree' do
        expect(Git::PathResolver).not_to receive(:root_of_worktree)
        repository
      end

      it 'forwards the repository and index options to resolve_paths' do
        repository
        expect(Git::PathResolver).to(
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
    let(:custom_index) { File.expand_path('/custom/index') }
    let(:custom_repository) { File.expand_path('/custom/.git') }
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
      allow(Git::PathResolver).to receive(:resolve_paths).and_return(resolved_paths)
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

      it 'forwards the directory to Commands::Clone#call expanded against the process working directory' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, File.join(Dir.pwd, 'my-repo'))
      end
    end

    context 'when a ~-prefixed directory argument is given' do
      include_context 'with a temporary home directory'

      let(:directory) { '~/my-repo' }

      it 'forwards the directory to Commands::Clone#call with ~ expanded to the home directory' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, File.join(home_dir, 'my-repo'))
      end
    end

    context 'when the directory argument cannot be expanded' do
      let(:directory) { 'my-repo' }

      before do
        allow(File).to receive(:expand_path).and_call_original
        allow(File).to receive(:expand_path).with('my-repo').and_raise(Errno::ENOENT, 'getcwd')
      end

      it 'raises Git::Error before running git' do
        expect { repository }.to raise_error(Git::Error, /Failed to resolve the working directory/)
        expect(clone_command).not_to have_received(:call)
      end

      context 'when :bare is given' do
        let(:options) { { bare: true } }

        it 'raises Git::Error naming the repository directory' do
          expect { repository }.to raise_error(Git::Error, /Failed to resolve the repository directory/)
        end
      end
    end

    it 'resolves paths using the working directory for non-bare clones' do
      repository
      expect(Git::PathResolver).to(
        have_received(:resolve_paths).with(working_directory: 'ruby-git', repository: nil, index: nil)
      )
    end

    context 'when the clone stderr cannot be parsed' do
      let(:clone_stderr) { "fatal: repository 'bogus' does not exist\n" }

      it 'raises Git::UnexpectedResultError' do
        expect { repository }.to raise_error(Git::UnexpectedResultError, /Unable to determine clone directory/)
      end
    end

    context 'when cloning a bare repository via :bare option' do
      let(:options) { { bare: true } }
      let(:clone_stderr) { "Cloning into bare repository 'ruby-git.git'...\n" }

      it 'resolves paths as a bare repository' do
        repository
        expect(Git::PathResolver).to(
          have_received(:resolve_paths).with(repository: 'ruby-git.git', bare: true, index: nil)
        )
      end
    end

    context 'when cloning with :mirror option' do
      let(:options) { { mirror: true } }
      let(:clone_stderr) { "Cloning into bare repository 'ruby-git.git'...\n" }

      it 'resolves paths as a bare repository' do
        repository
        expect(Git::PathResolver).to(
          have_received(:resolve_paths).with(repository: 'ruby-git.git', bare: true, index: nil)
        )
      end
    end

    context 'when :chdir is given' do
      let(:options) { { chdir: '/output' } }

      it 'prefixes the clone directory with chdir' do
        repository
        expect(Git::PathResolver).to(
          have_received(:resolve_paths).with(working_directory: '/output/ruby-git', repository: nil, index: nil)
        )
      end

      it 'forwards :chdir to Commands::Clone' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil, chdir: '/output')
      end

      context 'with a relative directory argument' do
        let(:directory) { 'my-repo' }

        it 'forwards the directory to Commands::Clone#call expanded against :chdir' do
          repository
          expect(clone_command).to(
            have_received(:call).with(repository_url, File.expand_path('my-repo', '/output'), chdir: '/output')
          )
        end
      end

      context 'with a ~-prefixed directory argument' do
        include_context 'with a temporary home directory'

        let(:directory) { '~/my-repo' }

        it 'forwards the directory to Commands::Clone#call with ~ expanded instead of joined onto :chdir' do
          repository
          expect(clone_command).to(
            have_received(:call).with(repository_url, File.join(home_dir, 'my-repo'), chdir: '/output')
          )
        end
      end

      context 'with a relative :index option' do
        let(:options) { { chdir: '/output', index: 'scratch.index' } }

        it 'expands the index against chdir' do
          repository
          expect(Git::PathResolver).to(
            have_received(:resolve_paths).with(
              working_directory: '/output/ruby-git',
              repository: nil,
              index: File.expand_path('scratch.index', '/output')
            )
          )
        end
      end

      context 'with an absolute :index option' do
        let(:options) { { chdir: '/output', index: '/abs/scratch.index' } }

        it 'ignores :chdir' do
          repository
          expect(Git::PathResolver).to(
            have_received(:resolve_paths).with(
              working_directory: '/output/ruby-git', repository: nil, index: File.expand_path('/abs/scratch.index')
            )
          )
        end
      end

      context 'with a ~-prefixed :index option' do
        include_context 'with a temporary home directory'

        let(:options) { { chdir: '/output', index: '~/scratch.index' } }

        it 'expands ~ to the home directory instead of joining it onto :chdir' do
          repository
          expect(Git::PathResolver).to(
            have_received(:resolve_paths).with(
              working_directory: '/output/ruby-git', repository: nil, index: File.join(home_dir, 'scratch.index')
            )
          )
        end
      end

      context 'when the :index option cannot be expanded' do
        let(:options) { { chdir: 'output', index: 'scratch.index' } }

        before do
          allow(File).to receive(:expand_path).and_call_original
          allow(File).to receive(:expand_path).with('scratch.index', 'output').and_raise(Errno::ENOENT)
        end

        it 'raises Git::Error' do
          expect { repository }.to raise_error(Git::Error, /Failed to resolve the index file/)
        end
      end

      context 'when the reported clone directory is absolute' do
        let(:clone_stderr) { "Cloning into '/abs/path'...\n" }

        it 'uses the absolute path as-is (ignores :chdir)' do
          repository
          expect(Git::PathResolver).to(
            have_received(:resolve_paths).with(working_directory: '/abs/path', repository: nil, index: nil)
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
      let(:options) { { index: custom_index } }
      let(:resolved_with_index) do
        { working_directory: 'ruby-git', repository: 'ruby-git/.git', index: custom_index }
      end

      before do
        allow(Git::PathResolver).to receive(:resolve_paths)
          .with(working_directory: 'ruby-git', repository: nil, index: custom_index)
          .and_return(resolved_with_index)
      end

      it 'forwards :index to path resolution' do
        repository
        expect(Git::PathResolver).to(
          have_received(:resolve_paths).with(working_directory: 'ruby-git', repository: nil, index: custom_index)
        )
      end

      it 'does not forward :index to Commands::Clone' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil)
      end
    end

    context 'with :repository option' do
      let(:options) { { repository: custom_repository } }

      it 'maps :repository to :separate_git_dir for Commands::Clone' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil, separate_git_dir: custom_repository)
      end
    end

    context 'with a relative :repository option' do
      let(:options) { { repository: 'custom.git' } }

      it 'expands :repository against the process working directory before git runs' do
        repository
        expect(clone_command).to(
          have_received(:call).with(repository_url, nil, separate_git_dir: File.expand_path('custom.git'))
        )
      end
    end

    context 'with a relative :repository option and :chdir' do
      let(:options) { { repository: 'custom.git', chdir: '/output' } }

      it 'expands :repository against :chdir before git runs' do
        repository
        expect(clone_command).to(
          have_received(:call).with(
            repository_url, nil, separate_git_dir: File.expand_path('custom.git', '/output'), chdir: '/output'
          )
        )
      end
    end

    context 'with a ~-prefixed :repository option' do
      include_context 'with a temporary home directory'

      let(:options) { { repository: '~/custom.git', chdir: '/output' } }

      it 'expands ~ to the home directory instead of joining it onto :chdir' do
        repository
        expect(clone_command).to(
          have_received(:call).with(
            repository_url, nil, separate_git_dir: File.join(home_dir, 'custom.git'), chdir: '/output'
          )
        )
      end
    end

    context 'with a :repository option that begins with ~user for a user that does not exist' do
      let(:options) { { repository: '~no-such-user-for-ruby-git/custom.git' } }

      it 'raises ArgumentError before git runs' do
        expect { repository }.to raise_error(ArgumentError)
        expect(clone_command).not_to have_received(:call)
      end
    end

    context 'with :repository option set to nil' do
      let(:options) { { repository: nil } }

      it 'does not pass :separate_git_dir to Commands::Clone' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil)
      end
    end

    context 'with :separate_git_dir option' do
      let(:options) { { separate_git_dir: 'custom.git', chdir: '/output' } }

      it 'expands :separate_git_dir against :chdir before git runs' do
        repository
        expect(clone_command).to(
          have_received(:call).with(
            repository_url, nil, separate_git_dir: File.expand_path('custom.git', '/output'), chdir: '/output'
          )
        )
      end
    end

    context 'with a ~-prefixed :separate_git_dir option' do
      include_context 'with a temporary home directory'

      let(:options) { { separate_git_dir: '~/custom.git' } }

      it 'expands ~ to the home directory before git runs' do
        repository
        expect(clone_command).to(
          have_received(:call).with(repository_url, nil, separate_git_dir: File.join(home_dir, 'custom.git'))
        )
      end
    end

    context 'with both :repository and :separate_git_dir options' do
      let(:options) { { repository: custom_repository, separate_git_dir: '~/other.git' } }

      it 'prefers :repository' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil, separate_git_dir: custom_repository)
      end
    end

    context 'with :repository set to nil and :separate_git_dir given' do
      let(:options) { { repository: nil, separate_git_dir: custom_repository } }

      it 'uses :separate_git_dir' do
        repository
        expect(clone_command).to have_received(:call).with(repository_url, nil, separate_git_dir: custom_repository)
      end
    end

    context 'with a v4.x option removed in v6.0.0' do
      # Let the real Commands::Clone bind the options so its validation runs
      before { allow(Git::Commands::Clone).to receive(:new).with(global_context).and_call_original }

      context 'with :path' do
        let(:options) { { path: '/output' } }

        it 'raises ArgumentError' do
          expect { repository }.to raise_error(ArgumentError, /Unsupported options: :path/)
        end
      end

      context 'with :recursive' do
        let(:options) { { recursive: true } }

        it 'raises ArgumentError' do
          expect { repository }.to raise_error(ArgumentError, /Unsupported options: :recursive/)
        end
      end

      context 'with :remote' do
        let(:options) { { remote: 'upstream' } }

        it 'raises ArgumentError' do
          expect { repository }.to raise_error(ArgumentError, /Unsupported options: :remote/)
        end
      end
    end
  end

  describe '.init' do
    subject(:repository) { host.init(directory, options) }

    let(:directory) { File.expand_path('/new-repo') }
    let(:options) { {} }
    let(:custom_index) { File.expand_path('/custom/index') }
    let(:custom_repository) { File.expand_path('/custom/git') }
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
      allow(Git::PathResolver).to(
        receive(:root_of_worktree).with(directory, any_args).and_return(directory)
      )
      allow(Git::PathResolver).to receive(:resolve_paths).and_return(resolved_paths)
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
        allow(Git::PathResolver).to receive(:resolve_paths)
          .with(repository: directory, bare: true, index: nil)
          .and_return(resolved_bare_paths)
      end

      it 'passes bare: true to Commands::Init' do
        repository
        expect(init_command).to have_received(:call).with(directory, bare: true)
      end

      it 'opens the result as a bare repository' do
        repository
        expect(Git::PathResolver).to(
          have_received(:resolve_paths).with(repository: directory, bare: true, index: nil)
        )
      end

      context 'with :index option' do
        let(:options) { { bare: true, index: custom_index } }

        it 'forwards :index to path resolution' do
          repository
          expect(Git::PathResolver).to(
            have_received(:resolve_paths).with(repository: directory, bare: true, index: custom_index)
          )
        end
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
      let(:options) { { repository: custom_repository } }
      let(:resolved_custom_paths) do
        { working_directory: '/new-repo', repository: custom_repository, index: '/custom/git/index' }
      end

      before do
        allow(Git::PathResolver).to receive(:resolve_paths)
          .with(working_directory: directory, repository: custom_repository, index: nil)
          .and_return(resolved_custom_paths)
      end

      it 'maps :repository to :separate_git_dir for Commands::Init' do
        repository
        expect(init_command).to have_received(:call).with(directory, separate_git_dir: custom_repository)
      end
    end

    context 'with a ~-prefixed directory' do
      include_context 'with a temporary home directory'

      let(:directory) { '~/scratch' }
      let(:expanded_directory) { File.join(home_dir, 'scratch') }

      before do
        allow(Dir).to receive(:exist?).with(expanded_directory).and_return(true)
        allow(Git::PathResolver).to(
          receive(:root_of_worktree).with(expanded_directory, any_args).and_return(expanded_directory)
        )
      end

      it 'passes the directory to Commands::Init with ~ expanded to the home directory' do
        repository
        expect(init_command).to have_received(:call).with(expanded_directory)
      end

      it 'opens the repository at the expanded directory' do
        repository
        expect(Git::PathResolver).to(
          have_received(:resolve_paths).with(working_directory: expanded_directory, repository: nil, index: nil)
        )
      end
    end

    context 'with a relative directory' do
      let(:directory) { 'scratch' }
      let(:expanded_directory) { File.join(Dir.pwd, 'scratch') }

      before do
        allow(Dir).to receive(:exist?).with(expanded_directory).and_return(true)
        allow(Git::PathResolver).to(
          receive(:root_of_worktree).with(expanded_directory, any_args).and_return(expanded_directory)
        )
      end

      it 'passes the directory to Commands::Init expanded against the process working directory' do
        repository
        expect(init_command).to have_received(:call).with(expanded_directory)
      end
    end

    context 'with a ~-prefixed :repository option' do
      include_context 'with a temporary home directory'

      let(:options) { { repository: '~/sep.git' } }
      let(:expanded_repository) { File.join(home_dir, 'sep.git') }

      it 'passes :separate_git_dir to Commands::Init with ~ expanded to the home directory' do
        repository
        expect(init_command).to have_received(:call).with(directory, separate_git_dir: expanded_repository)
      end

      it 'opens the repository with the expanded :repository' do
        repository
        expect(Git::PathResolver).to(
          have_received(:resolve_paths).with(working_directory: directory, repository: expanded_repository, index: nil)
        )
      end
    end

    context 'when the directory cannot be expanded' do
      let(:directory) { 'scratch' }

      before do
        allow(File).to receive(:expand_path).and_call_original
        allow(File).to receive(:expand_path).with('scratch').and_raise(Errno::ENOENT, 'getcwd')
      end

      it 'raises Git::Error before running git' do
        expect { repository }.to raise_error(Git::Error, /Failed to resolve the working directory/)
        expect(init_command).not_to have_received(:call)
      end

      context 'when :bare is given' do
        let(:options) { { bare: true } }

        it 'raises Git::Error naming the repository directory' do
          expect { repository }.to raise_error(Git::Error, /Failed to resolve the repository directory/)
        end
      end
    end

    context 'when the :repository option cannot be expanded' do
      let(:options) { { repository: 'sep.git' } }

      before do
        allow(File).to receive(:expand_path).and_call_original
        allow(File).to receive(:expand_path).with('sep.git').and_raise(Errno::ENOENT, 'getcwd')
      end

      it 'raises Git::Error before running git' do
        expect { repository }.to raise_error(Git::Error, /Failed to resolve the repository directory/)
        expect(init_command).not_to have_received(:call)
      end
    end

    context 'when :index option is given' do
      let(:options) { { index: custom_index } }
      let(:resolved_custom_index_paths) do
        { working_directory: '/new-repo', repository: '/new-repo/.git', index: custom_index }
      end

      before do
        allow(Git::PathResolver).to receive(:resolve_paths)
          .with(working_directory: directory, repository: nil, index: custom_index)
          .and_return(resolved_custom_index_paths)
      end

      it 'passes the custom index path through to Git.open' do
        repository
        expect(Git::PathResolver).to(
          have_received(:resolve_paths).with(working_directory: directory, repository: nil, index: custom_index)
        )
      end
    end

    context 'when :separate_git_dir option is given' do
      let(:options) { { separate_git_dir: custom_repository } }
      let(:resolved_custom_paths) do
        { working_directory: '/new-repo', repository: custom_repository, index: '/custom/git/index' }
      end

      before do
        allow(Git::PathResolver).to receive(:resolve_paths)
          .with(working_directory: directory, repository: custom_repository, index: nil)
          .and_return(resolved_custom_paths)
      end

      it 'normalizes :separate_git_dir to :repository before forwarding to Commands::Init' do
        repository
        expect(init_command).to have_received(:call).with(directory, separate_git_dir: custom_repository)
      end

      context 'when :repository key is present but nil' do
        let(:options) { { repository: nil, separate_git_dir: custom_repository } }

        it 'still normalizes :separate_git_dir to :repository before forwarding to Commands::Init' do
          repository
          expect(init_command).to have_received(:call).with(directory, separate_git_dir: custom_repository)
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
        allow(Git::PathResolver).to(
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
        allow(Git::PathResolver).to(
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
      allow(Git::PathResolver).to receive(:resolve_paths).and_return(resolved_paths)
      allow(Git::ExecutionContext::Repository).to receive(:from_hash).and_return(execution_context)
    end

    it 'returns a Git::Repository' do
      expect(repository).to be_a(Git::Repository)
    end

    it 'resolves the paths as a bare repository' do
      repository
      expect(Git::PathResolver).to(
        have_received(:resolve_paths).with(repository: git_dir, bare: true, index: nil)
      )
    end

    it 'builds the execution context from the merged options and resolved paths' do
      repository
      expect(Git::ExecutionContext::Repository).to(
        have_received(:from_hash).with(options.merge(resolved_paths), logger: nil)
      )
    end

    context 'with :index option' do
      let(:options) { { index: '/custom/index' } }

      it 'forwards :index to path resolution' do
        repository
        expect(Git::PathResolver).to(
          have_received(:resolve_paths).with(repository: git_dir, bare: true, index: '/custom/index')
        )
      end
    end
  end
end
