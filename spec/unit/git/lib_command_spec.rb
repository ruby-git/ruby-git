# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Lib do
  let(:base) { instance_double(Git::Base) }
  let(:logger) { Logger.new(nil) }
  let(:capturing_command_line) { instance_double(Git::CommandLine::Capturing) }
  let(:streaming_command_line) { instance_double(Git::CommandLine::Streaming) }

  subject(:lib) { described_class.new(base, logger) }

  before do
    allow(lib).to receive(:command_line_capturing).and_return(capturing_command_line)
    allow(lib).to receive(:command_line_streaming).and_return(streaming_command_line)
  end

  describe '#command_capturing' do
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
        allow(capturing_command_line).to receive(:run).and_return(successful_result)

        result = lib.command_capturing('version')

        expect(result).to be(successful_result)
      end
    end

    context 'when command fails with non-zero exit (default behavior)' do
      it 'raises Git::FailedError' do
        allow(capturing_command_line).to receive(:run).and_raise(Git::FailedError.new(failed_result))

        expect do
          lib.command_capturing('rev-parse', 'nonexistent')
        end.to raise_error(Git::FailedError)
      end
    end

    context 'when command fails with raise_on_failure: false' do
      it 'returns CommandLineResult without raising' do
        allow(capturing_command_line).to receive(:run).and_return(failed_result)

        result = lib.command_capturing('rev-parse', 'nonexistent', raise_on_failure: false)

        expect(result).to be(failed_result)
        expect(result.status.success?).to be false
      end
    end

    context 'with env: option' do
      it 'merges env into the command_line call' do
        allow(capturing_command_line).to receive(:run).and_return(successful_result)

        lib.command_capturing('rev-parse', '--git-dir', env: { 'GIT_DIR' => '/custom/path' })

        expect(capturing_command_line).to have_received(:run).with(
          'rev-parse', '--git-dir',
          hash_including(env: { 'GIT_DIR' => '/custom/path' })
        )
      end
    end
  end

  describe '#command_streaming (streaming path)' do
    let(:successful_result) do
      instance_double(
        Git::CommandLineResult,
        stdout: '',
        stderr: '',
        status: instance_double(Process::Status, success?: true)
      )
    end

    let(:failed_result) do
      instance_double(
        Git::CommandLineResult,
        git_cmd: %w[git cat-file --batch],
        stdout: '',
        stderr: 'fatal: not a git repository',
        status: instance_double(Process::Status, success?: false)
      )
    end

    context 'when command succeeds' do
      it 'delegates to CommandLine#run and returns a CommandLineResult' do
        allow(streaming_command_line).to receive(:run).and_return(successful_result)

        result = lib.command_streaming('cat-file', '--batch', out: StringIO.new)

        expect(result).to be(successful_result)
        expect(streaming_command_line).to have_received(:run).with(
          'cat-file', '--batch',
          hash_including(out: instance_of(StringIO))
        )
      end
    end

    context 'when command fails with non-zero exit (default behavior)' do
      it 'raises Git::FailedError' do
        allow(streaming_command_line).to receive(:run).and_raise(Git::FailedError.new(failed_result))

        expect do
          lib.command_streaming('cat-file', '--batch', out: StringIO.new)
        end.to raise_error(Git::FailedError)
      end
    end

    context 'when command fails with raise_on_failure: false' do
      it 'returns CommandLineResult without raising' do
        allow(streaming_command_line).to receive(:run).and_return(failed_result)

        result = lib.command_streaming('cat-file', '--batch', out: StringIO.new, raise_on_failure: false)

        expect(result).to be(failed_result)
        expect(result.status.success?).to be false
      end
    end

    context 'with env: option' do
      it 'passes env into the command_line call' do
        allow(streaming_command_line).to receive(:run).and_return(successful_result)

        lib.command_streaming('cat-file', out: StringIO.new, env: { 'GIT_DIR' => '/custom/path' })

        expect(streaming_command_line).to have_received(:run).with(
          'cat-file',
          hash_including(env: { 'GIT_DIR' => '/custom/path' })
        )
      end
    end

    context 'with out: option' do
      it 'passes out: to CommandLine#run' do
        out_io = StringIO.new
        allow(streaming_command_line).to receive(:run).and_return(successful_result)

        lib.command_streaming('show', 'HEAD:README', out: out_io)

        expect(streaming_command_line).to have_received(:run).with(
          'show', 'HEAD:README',
          hash_including(out: out_io)
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
        .with(progress: false)
        .and_return(command_result(fsck_output))

      result = lib.fsck

      expect(result).to be_a(Git::FsckResult)
      expect(result.dangling.size).to eq(1)
      expect(result.dangling.first.type).to eq(:blob)
      expect(result.dangling.first.oid).to eq('1234567890abcdef1234567890abcdef12345678')
    end

    it 'forwards objects and options to the command' do
      allow(fsck_command).to receive(:call)
        .with('abc1234', progress: false, strict: true)
        .and_return(command_result(''))

      result = lib.fsck('abc1234', strict: true)

      expect(fsck_command).to have_received(:call).with('abc1234', progress: false, strict: true)
      expect(result).to be_a(Git::FsckResult)
    end
  end

  describe '#diff_full' do
    let(:diff_command) { instance_double(Git::Commands::Diff) }

    before do
      allow(Git::Commands::Diff).to receive(:new).with(lib).and_return(diff_command)
    end

    it 'returns only the patch text from the combined output' do
      combined_output =
        "10\t2\tfile.rb\n 1 file changed, 10 insertions(+), 2 deletions(-)\n\n" \
        "diff --git a/file.rb b/file.rb\n--- a/file.rb\n+++ b/file.rb\n"
      allow(diff_command).to receive(:call)
        .and_return(command_result(combined_output))

      result = lib.diff_full

      expect(result).to eq("diff --git a/file.rb b/file.rb\n--- a/file.rb\n+++ b/file.rb\n")
    end

    it 'forwards obj1 and obj2 to the command' do
      allow(diff_command).to receive(:call)
        .with('HEAD~3', 'HEAD', patch: true, numstat: true, shortstat: true,
                                src_prefix: 'a/', dst_prefix: 'b/', path: nil)
        .and_return(command_result(''))

      lib.diff_full('HEAD~3', 'HEAD')

      expect(diff_command).to have_received(:call)
        .with('HEAD~3', 'HEAD', patch: true, numstat: true, shortstat: true,
                                src_prefix: 'a/', dst_prefix: 'b/', path: nil)
    end

    it 'forwards path_limiter as path' do
      allow(diff_command).to receive(:call)
        .with('HEAD', patch: true, numstat: true, shortstat: true,
                      src_prefix: 'a/', dst_prefix: 'b/', path: ['lib/'])
        .and_return(command_result(''))

      lib.diff_full('HEAD', nil, path_limiter: ['lib/'])

      expect(diff_command).to have_received(:call)
        .with('HEAD', patch: true, numstat: true, shortstat: true,
                      src_prefix: 'a/', dst_prefix: 'b/', path: ['lib/'])
    end

    it 'wraps a string path_limiter in an array' do
      allow(diff_command).to receive(:call)
        .with('HEAD', patch: true, numstat: true, shortstat: true,
                      src_prefix: 'a/', dst_prefix: 'b/', path: ['lib/foo.rb'])
        .and_return(command_result(''))

      lib.diff_full('HEAD', nil, path_limiter: 'lib/foo.rb')

      expect(diff_command).to have_received(:call)
        .with('HEAD', patch: true, numstat: true, shortstat: true,
                      src_prefix: 'a/', dst_prefix: 'b/', path: ['lib/foo.rb'])
    end

    it 'rejects unknown options' do
      expect { lib.diff_full('HEAD', nil, bogus: true) }
        .to raise_error(ArgumentError, /Unknown options: bogus/)
    end
  end

  describe '#diff_stats' do
    let(:diff_command) { instance_double(Git::Commands::Diff) }

    before do
      allow(Git::Commands::Diff).to receive(:new).with(lib).and_return(diff_command)
    end

    it 'parses the numstat output into a stats hash' do
      numstat_output = "10\t2\tlib/foo.rb\n3\t0\tREADME.md\n 2 files changed, 13 insertions(+), 2 deletions(-)\n"
      allow(diff_command).to receive(:call)
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
      allow(diff_command).to receive(:call)
        .with('HEAD~3', 'HEAD', numstat: true, shortstat: true,
                                src_prefix: 'a/', dst_prefix: 'b/', path: ['lib/'])
        .and_return(command_result(''))

      lib.diff_stats('HEAD~3', 'HEAD', path_limiter: ['lib/'])

      expect(diff_command).to have_received(:call)
        .with('HEAD~3', 'HEAD', numstat: true, shortstat: true,
                                src_prefix: 'a/', dst_prefix: 'b/', path: ['lib/'])
    end

    it 'rejects unknown options' do
      expect { lib.diff_stats('HEAD', nil, bogus: true) }
        .to raise_error(ArgumentError, /Unknown options: bogus/)
    end
  end

  describe '#diff_path_status' do
    let(:diff_command) { instance_double(Git::Commands::Diff) }

    before do
      allow(Git::Commands::Diff).to receive(:new).with(lib).and_return(diff_command)
    end

    it 'extracts name-status from raw output into a hash' do
      raw_output = ":100644 100644 abc1234 def5678 M\tlib/foo.rb\n" \
                   ":000000 100644 0000000 abc1234 A\tREADME.md\n"
      allow(diff_command).to receive(:call)
        .and_return(command_result(raw_output))

      result = lib.diff_path_status('HEAD~1', 'HEAD')

      expect(result).to eq({ 'lib/foo.rb' => 'M', 'README.md' => 'A' })
    end

    it 'handles renames by using the destination path' do
      raw_output = ":100644 100644 abc1234 def5678 R100\told.rb\tnew.rb\n"
      allow(diff_command).to receive(:call)
        .and_return(command_result(raw_output))

      result = lib.diff_path_status('HEAD~1', 'HEAD')

      expect(result).to eq({ 'new.rb' => 'R100' })
    end

    it 'forwards references and path_limiter to the command' do
      allow(diff_command).to receive(:call)
        .with('abc123', 'def456', raw: true, numstat: true, shortstat: true,
                                  src_prefix: 'a/', dst_prefix: 'b/', path: ['lib/'])
        .and_return(command_result(''))

      lib.diff_path_status('abc123', 'def456', path_limiter: ['lib/'])

      expect(diff_command).to have_received(:call)
        .with('abc123', 'def456', raw: true, numstat: true, shortstat: true,
                                  src_prefix: 'a/', dst_prefix: 'b/', path: ['lib/'])
    end

    it 'supports the deprecated :path option' do
      allow(Git::Deprecation).to receive(:warn)
      allow(diff_command).to receive(:call)
        .and_return(command_result(''))

      lib.diff_path_status('HEAD', nil, path: 'lib/foo.rb')

      expect(Git::Deprecation).to have_received(:warn).with(/deprecated/)
    end

    it 'rejects unknown options' do
      expect { lib.diff_path_status('HEAD', nil, bogus: true) }
        .to raise_error(ArgumentError, /Unknown options: bogus/)
    end
  end

  describe '#cat_file_contents' do
    let(:raw_command) { instance_double(Git::Commands::CatFile::Raw) }

    before do
      allow(Git::Commands::CatFile::Raw).to receive(:new).with(lib).and_return(raw_command)
    end

    it 'delegates to CatFile::Raw with -p and returns object content' do
      allow(raw_command).to receive(:call)
        .with('HEAD', p: true)
        .and_return(command_result('hello'))

      result = lib.cat_file_contents('HEAD')

      expect(raw_command).to have_received(:call).with('HEAD', p: true)
      expect(result).to eq('hello')
    end

    it 'streams content directly to a tempfile via the streaming path when given a block' do
      allow(raw_command).to receive(:call) do |_object, **kwargs|
        kwargs[:out].write('hello')
        command_result('')
      end

      yielded = nil
      lib.cat_file_contents('HEAD') { |file| yielded = file.read }

      expect(raw_command).to have_received(:call).with('HEAD', p: true, out: instance_of(File))
      expect(yielded).to eq('hello')
    end

    it 'does not buffer via the capturing path when a block is given' do
      allow(raw_command).to receive(:call) do |_object, **kwargs|
        kwargs[:out].write('hello')
        command_result('')
      end
      allow(capturing_command_line).to receive(:run)

      lib.cat_file_contents('HEAD', &:read)

      expect(capturing_command_line).not_to have_received(:run)
    end

    it 'rejects object values that look like options' do
      expect { lib.cat_file_contents('--all') }
        .to raise_error(ArgumentError)
    end
  end

  describe '#archive' do
    it 'uses the streaming execution path (not capturing) to write archive content' do
      Tempfile.create('archive_test') do |out_file|
        out_file.close
        allow(streaming_command_line).to receive(:run).and_return(command_result(''))

        lib.archive('HEAD', out_file.path)

        expect(streaming_command_line).to have_received(:run).with(
          'archive', '--format=zip', '--', 'HEAD',
          hash_including(out: instance_of(File))
        )
      end
    end

    it 'does not use the capturing path to write archive content' do
      Tempfile.create('archive_test') do |out_file|
        out_file.close
        allow(streaming_command_line).to receive(:run).and_return(command_result(''))
        allow(capturing_command_line).to receive(:run)

        lib.archive('HEAD', out_file.path)

        expect(capturing_command_line).not_to have_received(:run)
      end
    end
  end

  describe '#write_staged_content (private)' do
    it 'uses the streaming execution path to write staged content to the given IO' do
      out_io = StringIO.new

      allow(streaming_command_line).to receive(:run) do |*_args, **kwargs|
        kwargs[:out].write('staged content')
        command_result('')
      end

      result = lib.send(:write_staged_content, 'file.txt', 2, out_io)

      expect(streaming_command_line).to have_received(:run).with(
        'show', ':2:file.txt',
        hash_including(out: out_io)
      )
      expect(result).to be(out_io)
    end

    it 'does not use the capturing path for write_staged_content' do
      out_io = StringIO.new
      allow(streaming_command_line).to receive(:run).and_return(command_result(''))
      allow(capturing_command_line).to receive(:run)

      lib.send(:write_staged_content, 'file.txt', 3, out_io)

      expect(capturing_command_line).not_to have_received(:run)
    end
  end

  describe '#cat_file_type' do
    let(:batch_command) { instance_double(Git::Commands::CatFile::Batch) }

    before do
      allow(Git::Commands::CatFile::Batch).to receive(:new).with(lib).and_return(batch_command)
    end

    it 'delegates to CatFile::Batch with batch_check: and returns object type' do
      allow(batch_command).to receive(:call)
        .with('HEAD', batch_check: true)
        .and_return(command_result("abc123 commit 265\n"))

      result = lib.cat_file_type('HEAD')

      expect(batch_command).to have_received(:call).with('HEAD', batch_check: true)
      expect(result).to eq('commit')
    end

    it 'raises FailedError with a clear message when the object is missing' do
      allow(batch_command).to receive(:call)
        .with('nonexistent', batch_check: true)
        .and_return(command_result("nonexistent missing\n"))

      raw_command = instance_double(Git::Commands::CatFile::Raw)
      allow(Git::Commands::CatFile::Raw).to receive(:new).with(lib).and_return(raw_command)
      allow(raw_command).to receive(:call).with('nonexistent', p: true).and_raise(
        Git::FailedError.new(
          Git::CommandLineResult.new(
            %w[git cat-file -p nonexistent], nil,
            '', "fatal: Not a valid object name 'nonexistent'"
          )
        )
      )

      expect { lib.cat_file_type('nonexistent') }.to raise_error(Git::FailedError) do |error|
        expect(error.result.stderr).to include("Not a valid object name 'nonexistent'")
      end
    end
  end

  describe '#cat_file_size' do
    let(:batch_command) { instance_double(Git::Commands::CatFile::Batch) }

    before do
      allow(Git::Commands::CatFile::Batch).to receive(:new).with(lib).and_return(batch_command)
    end

    it 'delegates to CatFile::Batch with batch_check: and returns object size as Integer' do
      allow(batch_command).to receive(:call)
        .with('HEAD', batch_check: true)
        .and_return(command_result("abc123 commit 265\n"))

      result = lib.cat_file_size('HEAD')

      expect(batch_command).to have_received(:call).with('HEAD', batch_check: true)
      expect(result).to eq(265)
    end
  end

  describe '#cat_file_commit' do
    let(:raw_command) { instance_double(Git::Commands::CatFile::Raw) }

    before do
      allow(Git::Commands::CatFile::Raw).to receive(:new).with(lib).and_return(raw_command)
    end

    it 'delegates to CatFile::Raw with type commit and parses commit headers and message' do
      commit_body = "tree deadbeef\nauthor A <a@example.com> 1 +0000\ncommitter A <a@example.com> 1 +0000\n\nmessage"
      allow(raw_command).to receive(:call)
        .with('commit', 'HEAD')
        .and_return(command_result(commit_body))

      result = lib.cat_file_commit('HEAD')

      expect(raw_command).to have_received(:call).with('commit', 'HEAD')
      expect(result).to include(
        'sha' => 'HEAD',
        'tree' => 'deadbeef',
        'author' => 'A <a@example.com> 1 +0000',
        'committer' => 'A <a@example.com> 1 +0000',
        'message' => "message\n"
      )
    end
  end

  describe '#full_log_commits' do
    let(:log_command) { instance_double(Git::Commands::Log) }

    before do
      allow(Git::Commands::Log).to receive(:new).with(lib).and_return(log_command)
    end

    it 'passes color: false and pretty: "raw" as hardcoded parser-contract options' do
      allow(log_command).to receive(:call)
        .with(color: false, pretty: 'raw')
        .and_return(command_result(''))

      lib.full_log_commits

      expect(log_command).to have_received(:call).with(color: false, pretty: 'raw')
    end

    it 'forwards documented options to the command' do
      allow(log_command).to receive(:call)
        .with(color: false, pretty: 'raw', max_count: 5, all: true)
        .and_return(command_result(''))

      lib.full_log_commits(count: 5, all: true)

      expect(log_command).to have_received(:call)
        .with(color: false, pretty: 'raw', max_count: 5, all: true)
    end

    context 'with parser-contract options the facade owns' do
      it 'rejects :no_color because it is not a recognized option (facade uses color: false)' do
        expect { lib.full_log_commits(no_color: false) }
          .to raise_error(ArgumentError, /Unknown options: no_color/)
      end

      it 'rejects :pretty because the facade always sets it' do
        expect { lib.full_log_commits(pretty: 'oneline') }
          .to raise_error(ArgumentError, /Unknown options: pretty/)
      end
    end

    it 'rejects unknown options' do
      expect { lib.full_log_commits(bogus: true) }
        .to raise_error(ArgumentError, /Unknown options: bogus/)
    end

    context 'when the repository has no commits (unborn branch)' do
      it 'returns an empty array' do
        failed_result = command_result('', stderr: "fatal: your current branch 'main' does not have any commits yet",
                                           exitstatus: 128)
        allow(log_command).to receive(:call).and_raise(Git::FailedError, failed_result)

        expect(lib.full_log_commits).to eq([])
      end

      it 're-raises FailedError for other exit-128 errors' do
        failed_result = command_result('', stderr: 'fatal: bad default revision', exitstatus: 128)
        allow(log_command).to receive(:call).and_raise(Git::FailedError, failed_result)

        expect { lib.full_log_commits }.to raise_error(Git::FailedError)
      end
    end
  end

  describe '#grep' do
    let(:grep_command) { instance_double(Git::Commands::Grep) }

    before do
      allow(Git::Commands::Grep).to receive(:new).with(lib).and_return(grep_command)
    end

    it 'delegates to Grep and returns parsed matches' do
      output = "HEAD:lib/foo.rb:10:found it\nHEAD:lib/bar.rb:3:found it again\n"
      allow(grep_command).to receive(:call)
        .with('HEAD', pattern: 'found', no_color: true, line_number: true)
        .and_return(command_result(output, exitstatus: 0))

      result = lib.grep('found', object: 'HEAD')

      expect(grep_command).to have_received(:call).with('HEAD', pattern: 'found', no_color: true, line_number: true)
      expect(result).to eq(
        'HEAD:lib/foo.rb' => [[10, 'found it']],
        'HEAD:lib/bar.rb' => [[3, 'found it again']]
      )
    end

    it 'returns {} when exit status is 1 and stderr is empty (no matches)' do
      allow(grep_command).to receive(:call)
        .with('HEAD', pattern: 'nomatch', no_color: true, line_number: true)
        .and_return(command_result('', exitstatus: 1))

      result = lib.grep('nomatch')

      expect(result).to eq({})
    end

    it 'raises Git::FailedError when exit status is 1 and stderr is non-empty (real error)' do
      allow(grep_command).to receive(:call)
        .with('HEAD', pattern: 'search', no_color: true, line_number: true)
        .and_return(command_result('', stderr: 'fatal: bad object HEAD', exitstatus: 1))

      expect { lib.grep('search') }.to raise_error(Git::FailedError) do |error|
        expect(error.result.stderr).to include('fatal: bad object HEAD')
      end
    end

    it 'forwards :path_limiter as :pathspec to the Grep command' do
      allow(grep_command).to receive(:call)
        .with('HEAD', pattern: 'search', pathspec: 'lib/**', no_color: true, line_number: true)
        .and_return(command_result('', exitstatus: 0))

      lib.grep('search', path_limiter: 'lib/**')

      expect(grep_command).to have_received(:call)
        .with('HEAD', pattern: 'search', pathspec: 'lib/**', no_color: true, line_number: true)
    end

    it 'rejects unknown options' do
      expect { lib.grep('search', line_number: true) }.to raise_error(
        ArgumentError,
        /Unknown options: line_number/
      )
    end
  end

  describe '#cat_file_tag' do
    let(:raw_command) { instance_double(Git::Commands::CatFile::Raw) }

    before do
      allow(Git::Commands::CatFile::Raw).to receive(:new).with(lib).and_return(raw_command)
    end

    it 'delegates to CatFile::Raw with type tag and parses tag headers and message' do
      tag_body = "object deadbeef\ntype commit\ntag v1.0\ntagger A <a@example.com> 1 +0000\n\nrelease"
      allow(raw_command).to receive(:call)
        .with('tag', 'v1.0')
        .and_return(command_result(tag_body))

      result = lib.cat_file_tag('v1.0')

      expect(raw_command).to have_received(:call).with('tag', 'v1.0')
      expect(result).to include(
        'name' => 'v1.0',
        'object' => 'deadbeef',
        'type' => 'commit',
        'tag' => 'v1.0',
        'tagger' => 'A <a@example.com> 1 +0000',
        'message' => "release\n"
      )
    end
  end

  describe '#diff_files' do
    let(:diff_files_command) { instance_double(Git::Commands::DiffFiles) }
    let(:status_command) { instance_double(Git::Commands::Status) }

    # Raw line format: ":mode_src mode_dest sha_src sha_dest type\tpath"
    let(:raw_diff_output) do
      ":100644 100644 abc1234 def5678 M\tlib/foo.rb\n" \
        ":000000 100644 0000000 abc1234 A\tREADME.md\n"
    end

    before do
      allow(Git::Commands::DiffFiles).to receive(:new).with(lib).and_return(diff_files_command)
      allow(Git::Commands::Status).to receive(:new).with(lib).and_return(status_command)
      allow(status_command).to receive(:call).and_return(command_result(''))
    end

    it 'calls Git::Commands::Status to refresh the index before diffing' do
      allow(diff_files_command).to receive(:call).and_return(command_result(''))

      lib.diff_files

      expect(status_command).to have_received(:call).with(no_args)
    end

    it 'delegates to Git::Commands::DiffFiles#call with no arguments' do
      allow(diff_files_command).to receive(:call).and_return(command_result(''))

      lib.diff_files

      expect(diff_files_command).to have_received(:call).with(no_args)
    end

    it 'returns a Hash keyed by file path' do
      allow(diff_files_command).to receive(:call).and_return(command_result(raw_diff_output))

      result = lib.diff_files

      expect(result).to be_a(Hash)
      expect(result.keys).to contain_exactly('lib/foo.rb', 'README.md')
    end

    it 'populates all expected keys for each file' do
      allow(diff_files_command).to receive(:call).and_return(command_result(raw_diff_output))

      result = lib.diff_files

      expect(result['lib/foo.rb']).to eq(
        mode_index: '100644', mode_repo: '100644',
        path: 'lib/foo.rb', sha_repo: 'abc1234', sha_index: 'def5678',
        type: 'M'
      )
      expect(result['README.md']).to eq(
        mode_index: '100644', mode_repo: '000000',
        path: 'README.md', sha_repo: '0000000', sha_index: 'abc1234',
        type: 'A'
      )
    end

    it 'returns an empty Hash when there are no changes' do
      allow(diff_files_command).to receive(:call).and_return(command_result(''))

      result = lib.diff_files

      expect(result).to eq({})
    end
  end

  describe '#diff_index' do
    let(:diff_index_command) { instance_double(Git::Commands::DiffIndex) }
    let(:status_command) { instance_double(Git::Commands::Status) }

    let(:raw_diff_output) do
      ":100644 100644 abc1234 def5678 M\tlib/foo.rb\n" \
        ":000000 100644 0000000 abc1234 A\tREADME.md\n"
    end

    before do
      allow(Git::Commands::DiffIndex).to receive(:new).with(lib).and_return(diff_index_command)
      allow(Git::Commands::Status).to receive(:new).with(lib).and_return(status_command)
      allow(status_command).to receive(:call).and_return(command_result(''))
    end

    it 'calls Git::Commands::Status to refresh the index before diffing' do
      allow(diff_index_command).to receive(:call).and_return(command_result(''))

      lib.diff_index('HEAD')

      expect(status_command).to have_received(:call).with(no_args)
    end

    it 'delegates to Git::Commands::DiffIndex#call with the treeish argument' do
      allow(diff_index_command).to receive(:call).and_return(command_result(''))

      lib.diff_index('HEAD')

      expect(diff_index_command).to have_received(:call).with('HEAD')
    end

    it 'returns a Hash keyed by file path' do
      allow(diff_index_command).to receive(:call).and_return(command_result(raw_diff_output))

      result = lib.diff_index('HEAD')

      expect(result).to be_a(Hash)
      expect(result.keys).to contain_exactly('lib/foo.rb', 'README.md')
    end

    it 'populates all expected keys for each file' do
      allow(diff_index_command).to receive(:call).and_return(command_result(raw_diff_output))

      result = lib.diff_index('HEAD')

      expect(result['lib/foo.rb']).to eq(
        mode_index: '100644', mode_repo: '100644',
        path: 'lib/foo.rb', sha_repo: 'abc1234', sha_index: 'def5678',
        type: 'M'
      )
      expect(result['README.md']).to eq(
        mode_index: '100644', mode_repo: '000000',
        path: 'README.md', sha_repo: '0000000', sha_index: 'abc1234',
        type: 'A'
      )
    end

    it 'returns an empty Hash when there are no changes' do
      allow(diff_index_command).to receive(:call).and_return(command_result(''))

      result = lib.diff_index('HEAD')

      expect(result).to eq({})
    end
  end

  describe '#tag_sha' do
    let(:show_ref_list_command) { instance_double(Git::Commands::ShowRef::List) }
    let(:tag_ref_path) { '/fake/.git/refs/tags/v1.0' }

    before do
      lib.instance_variable_set(:@git_dir, '/fake/.git')
      allow(Git::Commands::ShowRef::List).to receive(:new).with(lib).and_return(show_ref_list_command)
      allow(File).to receive(:exist?).with(tag_ref_path).and_return(false)
    end

    context 'when the tag ref file exists in the local refs directory' do
      before do
        allow(File).to receive(:exist?).with(tag_ref_path).and_return(true)
        allow(File).to receive(:read).with(tag_ref_path).and_return("abc1234\n")
      end

      it 'reads the SHA directly from the file and returns it without the trailing newline' do
        result = lib.tag_sha('v1.0')

        expect(result).to eq('abc1234')
      end

      it 'does not call Git::Commands::ShowRef::List' do
        lib.tag_sha('v1.0')

        expect(Git::Commands::ShowRef::List).not_to have_received(:new)
      end
    end

    context 'when the tag ref file does not exist' do
      it 'delegates to Git::Commands::ShowRef::List with :tags and :hash options' do
        allow(show_ref_list_command).to receive(:call).and_return(command_result(''))

        lib.tag_sha('v1.0')

        expect(show_ref_list_command).to have_received(:call).with('v1.0', tags: true, hash: true)
      end

      it 'returns the SHA from the command stdout when the tag exists' do
        allow(show_ref_list_command).to receive(:call).and_return(command_result("abc1234\n"))

        result = lib.tag_sha('v1.0')

        expect(result).to eq("abc1234\n")
      end

      it 'returns an empty string when the tag is not found (exit status 1)' do
        allow(show_ref_list_command).to receive(:call).and_return(command_result('', exitstatus: 1))

        result = lib.tag_sha('v1.0')

        expect(result).to eq('')
      end
    end
  end

  describe '#branch_contains' do
    let(:list_command) { instance_double(Git::Commands::Branch::List) }
    let(:format_string) { Git::Parsers::Branch::FORMAT_STRING }

    before do
      allow(Git::Commands::Branch::List).to receive(:new).with(lib).and_return(list_command)
    end

    context 'when called with only a commit (no branch_name)' do
      it 'delegates to Branch::List with contains: and format: and no pattern' do
        allow(list_command).to receive(:call)
          .with(contains: 'abc123', format: format_string)
          .and_return(command_result("refs/heads/main|abc123|*|||\n"))

        lib.branch_contains('abc123')

        expect(list_command).to have_received(:call)
          .with(contains: 'abc123', format: format_string)
      end

      it 'returns the stdout of the command' do
        output = "refs/heads/main|abc123|*|||\n"
        allow(list_command).to receive(:call).and_return(command_result(output))

        result = lib.branch_contains('abc123')

        expect(result).to eq(output)
      end
    end

    context 'when called with an explicit branch_name pattern' do
      it 'passes the branch_name as a positional pattern to Branch::List' do
        allow(list_command).to receive(:call)
          .with('feature/*', contains: 'abc123', format: format_string)
          .and_return(command_result(''))

        lib.branch_contains('abc123', 'feature/*')

        expect(list_command).to have_received(:call)
          .with('feature/*', contains: 'abc123', format: format_string)
      end
    end

    context 'when branch_name is an empty string (default)' do
      it 'does not pass a pattern argument' do
        allow(list_command).to receive(:call)
          .with(contains: 'abc123', format: format_string)
          .and_return(command_result(''))

        lib.branch_contains('abc123', '')

        expect(list_command).to have_received(:call)
          .with(contains: 'abc123', format: format_string)
      end
    end

    context 'when branch_name is nil' do
      it 'treats nil as empty string and does not pass a pattern' do
        allow(list_command).to receive(:call)
          .with(contains: 'abc123', format: format_string)
          .and_return(command_result(''))

        lib.branch_contains('abc123', nil)

        expect(list_command).to have_received(:call)
          .with(contains: 'abc123', format: format_string)
      end
    end
  end
end
