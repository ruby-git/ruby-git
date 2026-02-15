# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Lib do
  let(:base) { instance_double(Git::Base) }
  let(:logger) { Logger.new(nil) }
  let(:command_line) { instance_double(Git::CommandLine) }

  subject(:lib) { described_class.new(base, logger) }

  before do
    allow(lib).to receive(:command_line).and_return(command_line)
  end

  describe '#command' do
    let(:successful_result) do
      instance_double(
        Git::CommandLineResult,
        stdout: 'git version 2.40.0',
        stderr: '',
        status: instance_double(Process::Status, success?: true)
      )
    end

    let(:failed_result) do
      instance_double(
        Git::CommandLineResult,
        git_cmd: %w[git rev-parse nonexistent],
        stdout: '',
        stderr: 'fatal: not a git repository',
        status: instance_double(Process::Status, success?: false)
      )
    end

    context 'when command succeeds' do
      it 'returns a CommandLineResult' do
        allow(command_line).to receive(:run).and_return(successful_result)

        result = lib.command('version')

        expect(result).to be(successful_result)
      end
    end

    context 'when command fails with non-zero exit (default behavior)' do
      it 'raises Git::FailedError' do
        allow(command_line).to receive(:run).and_raise(Git::FailedError.new(failed_result))

        expect do
          lib.command('rev-parse', 'nonexistent')
        end.to raise_error(Git::FailedError)
      end
    end

    context 'when command fails with raise_on_failure: false' do
      it 'returns CommandLineResult without raising' do
        allow(command_line).to receive(:run).and_return(failed_result)

        result = lib.command('rev-parse', 'nonexistent', raise_on_failure: false)

        expect(result).to be(failed_result)
        expect(result.status.success?).to be false
      end
    end

    context 'with env: option' do
      it 'merges env into the command_line call' do
        allow(command_line).to receive(:run).and_return(successful_result)

        lib.command('rev-parse', '--git-dir', env: { 'GIT_DIR' => '/custom/path' })

        expect(command_line).to have_received(:run).with(
          'rev-parse', '--git-dir',
          hash_including(env: { 'GIT_DIR' => '/custom/path' })
        )
      end
    end
  end

  describe '#clone' do
    let(:repository_url) { 'https://github.com/ruby-git/ruby-git.git' }
    let(:directory) { 'ruby-git' }
    let(:clone_command) { instance_double(Git::Commands::Clone) }

    def clone_stderr(dir, bare: false)
      bare ? "Cloning into bare repository '#{dir}'...\n" : "Cloning into '#{dir}'...\n"
    end

    before do
      allow(Git::Commands::Clone).to receive(:new).with(lib).and_return(clone_command)
    end

    context 'with default options' do
      it 'returns a hash with working_directory' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr(directory)))

        result = lib.clone(repository_url, directory)

        expect(clone_command).to have_received(:call).with(repository_url, directory)
        expect(result).to eq({ working_directory: directory })
      end
    end

    context 'with :bare option' do
      it 'returns a hash with repository' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr(directory, bare: true)))

        result = lib.clone(repository_url, directory, bare: true)

        expect(clone_command).to have_received(:call).with(repository_url, directory, bare: true)
        expect(result).to eq({ repository: directory })
      end
    end

    context 'with :mirror option' do
      it 'returns a hash with repository' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr(directory, bare: true)))

        result = lib.clone(repository_url, directory, mirror: true)

        expect(clone_command).to have_received(:call).with(repository_url, directory, mirror: true)
        expect(result).to eq({ repository: directory })
      end
    end

    context 'with :path option' do
      it 'uses path as the directory in result' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr('custom/path')))

        result = lib.clone(repository_url, directory, path: 'custom/path')

        expect(clone_command).to have_received(:call).with(repository_url, 'custom/path')
        expect(result).to eq({ working_directory: 'custom/path' })
      end

      it 'uses path with bare option' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr('custom/path', bare: true)))

        result = lib.clone(repository_url, directory, path: 'custom/path', bare: true)

        expect(clone_command).to have_received(:call).with(repository_url, 'custom/path', bare: true)
        expect(result).to eq({ repository: 'custom/path' })
      end
    end

    context 'with nil directory' do
      it 'derives directory from git output' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr('ruby-git')))

        result = lib.clone(repository_url, nil)

        expect(clone_command).to have_received(:call).with(repository_url, nil)
        expect(result).to eq({ working_directory: 'ruby-git' })
      end

      it 'detects bare repository from git output' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr('ruby-git.git', bare: true)))

        result = lib.clone(repository_url, nil, bare: true)

        expect(clone_command).to have_received(:call).with(repository_url, nil, bare: true)
        expect(result).to eq({ repository: 'ruby-git.git' })
      end

      it 'detects mirror repository from git output' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr('ruby-git.git', bare: true)))

        result = lib.clone(repository_url, nil, mirror: true)

        expect(clone_command).to have_received(:call).with(repository_url, nil, mirror: true)
        expect(result).to eq({ repository: 'ruby-git.git' })
      end
    end

    context 'with :log option' do
      it 'includes log in the result' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr(directory)))
        logger = double('Logger')

        result = lib.clone(repository_url, directory, log: logger)

        expect(clone_command).to have_received(:call).with(repository_url, directory)
        expect(result).to eq({ working_directory: directory, log: logger })
      end
    end

    context 'with :git_ssh option' do
      it 'includes git_ssh in the result' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr(directory)))

        result = lib.clone(repository_url, directory, git_ssh: 'ssh -i /path/to/key')

        expect(clone_command).to have_received(:call).with(repository_url, directory)
        expect(result).to eq({ working_directory: directory, git_ssh: 'ssh -i /path/to/key' })
      end

      it 'includes git_ssh even when nil' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr(directory)))

        result = lib.clone(repository_url, directory, git_ssh: nil)

        expect(clone_command).to have_received(:call).with(repository_url, directory)
        expect(result).to have_key(:git_ssh)
        expect(result[:git_ssh]).to be_nil
      end
    end

    context 'with multiple options' do
      it 'includes all result fields' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr(directory)))
        logger = double('Logger')

        result = lib.clone(repository_url, directory, log: logger, git_ssh: 'custom-ssh')

        expect(clone_command).to have_received(:call).with(repository_url, directory)
        expect(result).to eq(
          working_directory: directory,
          log: logger,
          git_ssh: 'custom-ssh'
        )
      end

      it 'combines bare, log, and git_ssh' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr(directory, bare: true)))
        logger = double('Logger')

        result = lib.clone(repository_url, directory, bare: true, log: logger, git_ssh: nil)

        expect(clone_command).to have_received(:call).with(repository_url, directory, bare: true)
        expect(result).to eq(
          repository: directory,
          log: logger,
          git_ssh: nil
        )
      end
    end
  end

  describe '#fsck' do
    let(:fsck_command) { instance_double(Git::Commands::Fsck) }

    before do
      allow(Git::Commands::Fsck).to receive(:new).with(lib).and_return(fsck_command)
    end

    it 'parses the command output into a FsckResult' do
      fsck_output = "dangling blob 1234567890abcdef1234567890abcdef12345678\n"
      allow(fsck_command).to receive(:call)
        .and_return(command_result(fsck_output))

      result = lib.fsck

      expect(result).to be_a(Git::FsckResult)
      expect(result.dangling.size).to eq(1)
      expect(result.dangling.first.type).to eq(:blob)
      expect(result.dangling.first.oid).to eq('1234567890abcdef1234567890abcdef12345678')
    end

    it 'forwards objects and options to the command' do
      allow(fsck_command).to receive(:call)
        .with('abc1234', strict: true)
        .and_return(command_result(''))

      result = lib.fsck('abc1234', strict: true)

      expect(fsck_command).to have_received(:call).with('abc1234', strict: true)
      expect(result).to be_a(Git::FsckResult)
    end
  end
end
