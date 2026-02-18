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

    context 'with :chdir option' do
      let(:chdir) { '/parent/dir' }

      it 'passes chdir to clone command and prefixes result working_directory' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr(directory)))

        result = lib.clone(repository_url, directory, chdir: chdir)

        expect(clone_command).to have_received(:call).with(repository_url, directory, chdir: chdir)
        expect(result).to eq({ working_directory: "#{chdir}/#{directory}" })
      end

      it 'passes chdir to clone command and prefixes bare repository result' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr(directory, bare: true)))

        result = lib.clone(repository_url, directory, chdir: chdir, bare: true)

        expect(clone_command).to have_received(:call).with(repository_url, directory, chdir: chdir, bare: true)
        expect(result).to eq({ repository: "#{chdir}/#{directory}" })
      end

      it 'prefixes the derived directory name when directory is nil' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr('ruby-git')))

        result = lib.clone(repository_url, nil, chdir: chdir)

        expect(clone_command).to have_received(:call).with(repository_url, nil, chdir: chdir)
        expect(result).to eq({ working_directory: "#{chdir}/ruby-git" })
      end

      it 'does not modify :log in the result when :chdir is given' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr(directory)))

        result = lib.clone(repository_url, directory, chdir: chdir, log: logger)

        expect(result[:log]).to be(logger)
        expect(result[:working_directory]).to eq("#{chdir}/#{directory}")
      end

      it 'does not modify :git_ssh in the result when :chdir is given' do
        git_ssh = '/usr/bin/my-ssh'
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr(directory)))

        result = lib.clone(repository_url, directory, chdir: chdir, git_ssh: git_ssh)

        expect(result[:git_ssh]).to eq(git_ssh)
        expect(result[:working_directory]).to eq("#{chdir}/#{directory}")
      end
    end

    context 'with deprecated :path option' do
      let(:chdir) { '/parent/dir' }

      it 'emits a deprecation warning' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr(directory)))
        allow(Git::Deprecation).to receive(:warn)

        lib.clone(repository_url, directory, path: chdir)

        expect(Git::Deprecation).to have_received(:warn).with(
          'The :path option for Git::Lib#clone is deprecated, use :chdir instead'
        )
      end

      it 'behaves like :chdir — passes chdir to clone and prefixes result' do
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr(directory)))
        allow(Git::Deprecation).to receive(:warn)

        result = lib.clone(repository_url, directory, path: chdir)

        expect(clone_command).to have_received(:call).with(repository_url, directory, chdir: chdir)
        expect(result).to eq({ working_directory: "#{chdir}/#{directory}" })
      end

      it 'prefers :chdir over :path when both are given, and still warns' do
        other_dir = '/other/dir'
        allow(clone_command).to receive(:call)
          .and_return(command_result(stderr: clone_stderr(directory)))
        allow(Git::Deprecation).to receive(:warn)

        result = lib.clone(repository_url, directory, chdir: chdir, path: other_dir)

        expect(clone_command).to have_received(:call).with(repository_url, directory, chdir: chdir)
        expect(result).to eq({ working_directory: "#{chdir}/#{directory}" })
        expect(Git::Deprecation).to have_received(:warn).with(
          'The :path option for Git::Lib#clone is deprecated, use :chdir instead'
        )
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

  describe '#diff_full' do
    let(:patch_command) { instance_double(Git::Commands::Diff::Patch) }

    before do
      allow(Git::Commands::Diff::Patch).to receive(:new).with(lib).and_return(patch_command)
    end

    it 'returns only the patch text from the combined output' do
      combined_output =
        "10\t2\tfile.rb\n 1 file changed, 10 insertions(+), 2 deletions(-)\n\n" \
        "diff --git a/file.rb b/file.rb\n--- a/file.rb\n+++ b/file.rb\n"
      allow(patch_command).to receive(:call)
        .and_return(command_result(combined_output))

      result = lib.diff_full

      expect(result).to eq("diff --git a/file.rb b/file.rb\n--- a/file.rb\n+++ b/file.rb\n")
    end

    it 'forwards obj1 and obj2 to the command' do
      allow(patch_command).to receive(:call)
        .with('HEAD~3', 'HEAD', pathspecs: nil)
        .and_return(command_result(''))

      lib.diff_full('HEAD~3', 'HEAD')

      expect(patch_command).to have_received(:call)
        .with('HEAD~3', 'HEAD', pathspecs: nil)
    end

    it 'forwards path_limiter as pathspecs' do
      allow(patch_command).to receive(:call)
        .with('HEAD', pathspecs: ['lib/'])
        .and_return(command_result(''))

      lib.diff_full('HEAD', nil, path_limiter: ['lib/'])

      expect(patch_command).to have_received(:call)
        .with('HEAD', pathspecs: ['lib/'])
    end

    it 'wraps a string path_limiter in an array' do
      allow(patch_command).to receive(:call)
        .with('HEAD', pathspecs: ['lib/foo.rb'])
        .and_return(command_result(''))

      lib.diff_full('HEAD', nil, path_limiter: 'lib/foo.rb')

      expect(patch_command).to have_received(:call)
        .with('HEAD', pathspecs: ['lib/foo.rb'])
    end

    it 'rejects unknown options' do
      expect { lib.diff_full('HEAD', nil, bogus: true) }
        .to raise_error(ArgumentError, /Unknown options: bogus/)
    end
  end

  describe '#diff_stats' do
    let(:numstat_command) { instance_double(Git::Commands::Diff::Numstat) }

    before do
      allow(Git::Commands::Diff::Numstat).to receive(:new).with(lib).and_return(numstat_command)
    end

    it 'parses the numstat output into a stats hash' do
      numstat_output = "10\t2\tlib/foo.rb\n3\t0\tREADME.md\n 2 files changed, 13 insertions(+), 2 deletions(-)\n"
      allow(numstat_command).to receive(:call)
        .and_return(command_result(numstat_output))

      result = lib.diff_stats

      expect(result).to be_a(Hash)
      expect(result[:total][:insertions]).to eq(13)
      expect(result[:total][:deletions]).to eq(2)
      expect(result[:total][:files]).to eq(2)
      expect(result[:files]).to have_key('lib/foo.rb')
      expect(result[:files]).to have_key('README.md')
    end

    it 'forwards obj1, obj2, and path_limiter to the command' do
      allow(numstat_command).to receive(:call)
        .with('HEAD~3', 'HEAD', pathspecs: ['lib/'])
        .and_return(command_result(''))

      lib.diff_stats('HEAD~3', 'HEAD', path_limiter: ['lib/'])

      expect(numstat_command).to have_received(:call)
        .with('HEAD~3', 'HEAD', pathspecs: ['lib/'])
    end

    it 'rejects unknown options' do
      expect { lib.diff_stats('HEAD', nil, bogus: true) }
        .to raise_error(ArgumentError, /Unknown options: bogus/)
    end
  end

  describe '#diff_path_status' do
    let(:raw_command) { instance_double(Git::Commands::Diff::Raw) }

    before do
      allow(Git::Commands::Diff::Raw).to receive(:new).with(lib).and_return(raw_command)
    end

    it 'extracts name-status from raw output into a hash' do
      raw_output = ":100644 100644 abc1234 def5678 M\tlib/foo.rb\n" \
                   ":000000 100644 0000000 abc1234 A\tREADME.md\n"
      allow(raw_command).to receive(:call)
        .and_return(command_result(raw_output))

      result = lib.diff_path_status('HEAD~1', 'HEAD')

      expect(result).to eq({ 'lib/foo.rb' => 'M', 'README.md' => 'A' })
    end

    it 'handles renames by using the destination path' do
      raw_output = ":100644 100644 abc1234 def5678 R100\told.rb\tnew.rb\n"
      allow(raw_command).to receive(:call)
        .and_return(command_result(raw_output))

      result = lib.diff_path_status('HEAD~1', 'HEAD')

      expect(result).to eq({ 'new.rb' => 'R100' })
    end

    it 'forwards references and path_limiter to the command' do
      allow(raw_command).to receive(:call)
        .with('abc123', 'def456', pathspecs: ['lib/'])
        .and_return(command_result(''))

      lib.diff_path_status('abc123', 'def456', path_limiter: ['lib/'])

      expect(raw_command).to have_received(:call)
        .with('abc123', 'def456', pathspecs: ['lib/'])
    end

    it 'supports the deprecated :path option' do
      allow(Git::Deprecation).to receive(:warn)
      allow(raw_command).to receive(:call)
        .and_return(command_result(''))

      lib.diff_path_status('HEAD', nil, path: 'lib/foo.rb')

      expect(Git::Deprecation).to have_received(:warn).with(/deprecated/)
    end

    it 'rejects unknown options' do
      expect { lib.diff_path_status('HEAD', nil, bogus: true) }
        .to raise_error(ArgumentError, /Unknown options: bogus/)
    end
  end
end
