# frozen_string_literal: true

require 'spec_helper'
require 'git/repository/path_resolver'

RSpec.describe Git::Repository::PathResolver do
  describe '.resolve_paths' do
    subject(:paths) { described_class.resolve_paths(**args) }

    context 'with a working directory for a non-bare repository' do
      let(:args) { { working_directory: '/repo' } }

      it 'resolves the working directory to an absolute path' do
        expect(paths[:working_directory]).to eq(File.expand_path('/repo'))
      end

      it 'defaults the repository to <working_directory>/.git' do
        expect(paths[:repository]).to eq(File.expand_path('/repo/.git'))
      end

      it 'defaults the index to <repository>/index' do
        expect(paths[:index]).to eq(File.expand_path('/repo/.git/index'))
      end
    end

    context 'when no working directory is given for a non-bare repository' do
      let(:args) { {} }

      it 'defaults the working directory to the current directory' do
        expect(paths[:working_directory]).to eq(File.expand_path(Dir.pwd))
      end
    end

    context 'with an explicit repository path' do
      let(:args) { { working_directory: '/repo', repository: '/custom/git' } }

      it 'uses the given repository path' do
        expect(paths[:repository]).to eq(File.expand_path('/custom/git'))
      end
    end

    context 'with an explicit index path' do
      let(:args) { { working_directory: '/repo', index: '/custom/index' } }

      it 'uses the given index path' do
        expect(paths[:index]).to eq(File.expand_path('/custom/index'))
      end
    end

    context 'when the repository is bare' do
      let(:args) { { repository: '/repo.git', bare: true } }

      it 'resolves the working directory to nil' do
        expect(paths[:working_directory]).to be_nil
      end

      it 'uses the given repository path' do
        expect(paths[:repository]).to eq(File.expand_path('/repo.git'))
      end

      it 'places the index inside the repository' do
        expect(paths[:index]).to eq(File.expand_path('/repo.git/index'))
      end
    end

    context 'when the repository is bare and no repository path is given' do
      around { |example| Dir.chdir(Dir.tmpdir) { example.run } }

      let(:args) { { bare: true } }

      it 'defaults the repository to the current directory' do
        expect(paths[:repository]).to eq(File.expand_path(Dir.pwd))
      end
    end

    context 'when the repository path is a gitdir pointer file' do
      let(:tmp_dir) { Dir.mktmpdir }
      let(:pointer_file) { File.join(tmp_dir, '.git') }
      let(:target_dir) { File.join(tmp_dir, 'actual-git-dir') }
      let(:args) { { working_directory: tmp_dir, repository: pointer_file } }

      before do
        FileUtils.mkdir_p(target_dir)
        File.write(pointer_file, "gitdir: #{target_dir}\n")
      end

      after { FileUtils.rm_rf(tmp_dir) }

      it 'follows the pointer to the target repository directory' do
        expect(paths[:repository]).to eq(File.expand_path(target_dir))
      end
    end

    context 'when the repository path is a gitdir pointer with a relative target' do
      let(:tmp_dir) { Dir.mktmpdir }
      let(:pointer_base) { File.join(tmp_dir, 'pointer-base') }
      let(:other_working_dir) { File.join(tmp_dir, 'other-working-dir') }
      let(:pointer_file) { File.join(pointer_base, '.git') }
      let(:args) { { working_directory: other_working_dir, repository: pointer_file } }

      before do
        FileUtils.mkdir_p(pointer_base)
        FileUtils.mkdir_p(other_working_dir)
        File.write(pointer_file, "gitdir: actual-git-dir\n")
      end

      after { FileUtils.rm_rf(tmp_dir) }

      it 'resolves the relative target against the pointer file directory' do
        expect(paths[:repository]).to eq(File.expand_path('actual-git-dir', pointer_base))
      end

      it 'does not resolve the relative target against working_directory' do
        expect(paths[:repository]).not_to eq(File.expand_path('actual-git-dir', other_working_dir))
      end
    end

    context 'when the repository path is a file without a gitdir pointer' do
      let(:tmp_dir) { Dir.mktmpdir }
      let(:plain_file) { File.join(tmp_dir, '.git') }
      let(:args) { { working_directory: tmp_dir, repository: plain_file } }

      before { File.write(plain_file, "not a pointer\n") }

      after { FileUtils.rm_rf(tmp_dir) }

      it 'returns the file path unchanged' do
        expect(paths[:repository]).to eq(File.expand_path(plain_file))
      end
    end
  end

  describe '.root_of_worktree' do
    subject(:root) { described_class.root_of_worktree(working_dir, **call_options) }

    let(:working_dir) { Dir.mktmpdir }
    let(:call_options) { {} }
    let(:execution_context) { instance_double(Git::ExecutionContext::Global) }
    let(:rev_parse_command) { instance_double(Git::Commands::RevParse) }

    before do
      allow(Git::ExecutionContext::Global).to receive(:new).and_return(execution_context)
      allow(Git::Commands::RevParse).to receive(:new).with(execution_context).and_return(rev_parse_command)
    end

    after { FileUtils.rm_rf(working_dir) }

    context 'when the directory is inside a working tree' do
      before do
        allow(rev_parse_command).to(
          receive(:call)
            .with(show_toplevel: true, chdir: File.expand_path(working_dir))
            .and_return(command_result('/toplevel'))
        )
      end

      it 'returns the toplevel reported by git rev-parse' do
        expect(root).to eq('/toplevel')
      end

      it 'constructs an execution context with default binary_path and git_ssh' do
        expect(Git::ExecutionContext::Global).to(
          receive(:new).with(binary_path: :use_global_config, git_ssh: :use_global_config)
        )
        root
      end
    end

    context 'when binary_path is given' do
      let(:call_options) { { binary_path: '/custom/git' } }

      before do
        allow(rev_parse_command).to receive(:call).and_return(command_result('/toplevel'))
      end

      it 'passes the binary_path to the execution context' do
        expect(Git::ExecutionContext::Global).to(
          receive(:new).with(binary_path: '/custom/git', git_ssh: :use_global_config)
        )
        root
      end
    end

    context 'when git_ssh is given' do
      let(:call_options) { { git_ssh: '/custom/ssh' } }

      before do
        allow(rev_parse_command).to receive(:call).and_return(command_result('/toplevel'))
      end

      it 'passes the git_ssh to the execution context' do
        expect(Git::ExecutionContext::Global).to(
          receive(:new).with(binary_path: :use_global_config, git_ssh: '/custom/ssh')
        )
        root
      end
    end

    context 'when git_ssh is nil (explicitly unset)' do
      let(:call_options) { { git_ssh: nil } }

      before do
        allow(rev_parse_command).to receive(:call).and_return(command_result('/toplevel'))
      end

      it 'passes nil git_ssh to the execution context' do
        expect(Git::ExecutionContext::Global).to(
          receive(:new).with(binary_path: :use_global_config, git_ssh: nil)
        )
        root
      end
    end

    context 'when the directory does not exist' do
      let(:working_dir) do
        # Generate a path that is guaranteed not to exist by creating and
        # immediately deleting a temp directory.
        path = Dir.mktmpdir
        FileUtils.rm_rf(path)
        path
      end

      it 'raises ArgumentError indicating the directory does not exist' do
        expect { root }.to raise_error(ArgumentError, /does not exist/)
      end
    end

    context 'when the path is a file rather than a directory' do
      let(:parent_dir) { Dir.mktmpdir }
      let(:working_dir) do
        path = File.join(parent_dir, 'not-a-dir')
        File.write(path, '')
        path
      end

      after { FileUtils.rm_rf(parent_dir) }

      it 'raises ArgumentError indicating the path is not a directory' do
        expect { root }.to raise_error(ArgumentError, /is not a directory/)
      end
    end

    context 'when the git binary cannot be found' do
      before do
        allow(rev_parse_command).to receive(:call).and_raise(Errno::ENOENT)
      end

      it 'raises ArgumentError indicating the git binary was not found' do
        expect { root }.to raise_error(ArgumentError, /git binary not found/)
      end
    end

    context 'when the directory is not in a git working tree' do
      before do
        failure = Git::FailedError.new(command_result('', stderr: 'fatal', exitstatus: 128))
        allow(rev_parse_command).to receive(:call).and_raise(failure)
      end

      it 'raises ArgumentError indicating the directory is not in a working tree' do
        expect { root }.to raise_error(ArgumentError, /is not in a git working tree/)
      end
    end
  end
end
