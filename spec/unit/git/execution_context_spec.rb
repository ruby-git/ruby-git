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

  describe '#env_overrides' do
    subject(:env) { context.env_overrides(**additional_overrides) }

    let(:context) do
      Git::ExecutionContext::Repository.new(
        git_dir: git_dir,
        git_work_dir: git_work_dir,
        git_index_file: git_index_file,
        git_ssh: git_ssh
      )
    end
    let(:git_dir)              { '/fake/repo/.git' }
    let(:git_work_dir)         { '/fake/repo' }
    let(:git_index_file)       { '/fake/repo/.git/index' }
    let(:git_ssh)              { :use_global_config }
    let(:additional_overrides) { {} }

    before { allow(Git::Config.instance).to receive(:git_ssh).and_return('/configured/ssh') }

    context 'when no additional overrides are given' do
      it 'returns the default environment variables for the context' do
        expect(env).to eq(
          'GIT_DIR' => '/fake/repo/.git',
          'GIT_WORK_TREE' => '/fake/repo',
          'GIT_INDEX_FILE' => '/fake/repo/.git/index',
          'GIT_SSH' => '/configured/ssh',
          'GIT_EDITOR' => 'true',
          'LC_ALL' => expected_lc_all
        )
      end

      it 'resolves GIT_SSH from the global config on each call' do
        allow(Git::Config.instance).to receive(:git_ssh).and_return('/first/ssh', '/second/ssh')
        expect(context.env_overrides['GIT_SSH']).to eq('/first/ssh')
        expect(context.env_overrides['GIT_SSH']).to eq('/second/ssh')
      end
    end

    # The pinned locale has to name a locale that exists on the platform it applies to,
    # or the git subprocess falls back to a C ctype and matches bytes rather than
    # characters. Every branch is asserted on every host so none can rot on a platform
    # CI does not run — there is no macOS job in the matrix.
    #
    # `RUBY_PLATFORM` and `RUBY_DESCRIPTION` are stubbed together because the platform
    # is read from the latter when the former is `'java'`; stubbing only one would leave
    # the host's real platform visible through the other.
    describe 'the LC_ALL pin' do
      context 'when running on Darwin' do
        before do
          stub_const('RUBY_PLATFORM', 'arm64-darwin24')
          stub_const('RUBY_DESCRIPTION', 'ruby 3.4.1 (2024-12-25 revision abc1234) [arm64-darwin24]')
        end

        it 'pins LC_ALL to en_US.UTF-8' do
          expect(env).to include('LC_ALL' => 'en_US.UTF-8')
        end
      end

      context 'when running on a platform other than Darwin' do
        before do
          stub_const('RUBY_PLATFORM', 'x86_64-linux')
          stub_const('RUBY_DESCRIPTION', 'ruby 3.4.1 (2024-12-25 revision abc1234) [x86_64-linux]')
        end

        it 'pins LC_ALL to C.UTF-8' do
          expect(env).to include('LC_ALL' => 'C.UTF-8')
        end
      end

      # JRuby reports RUBY_PLATFORM as 'java' on every host and records the real
      # platform only in RUBY_DESCRIPTION. A Darwin check that consults only
      # RUBY_PLATFORM would put JRuby on macOS onto the non-Darwin branch — the one
      # pairing that branch exists to prevent, since macOS 11-14 have no C.UTF-8.
      context 'when running under JRuby on Darwin' do
        before do
          stub_const('RUBY_PLATFORM', 'java')
          stub_const('RUBY_DESCRIPTION', 'jruby 10.0.0.1 (3.4.2) OpenJDK 64-Bit Server VM [arm64-darwin]')
        end

        it 'pins LC_ALL to en_US.UTF-8' do
          expect(env).to include('LC_ALL' => 'en_US.UTF-8')
        end
      end

      context 'when running under JRuby on a platform other than Darwin' do
        before do
          stub_const('RUBY_PLATFORM', 'java')
          stub_const('RUBY_DESCRIPTION', 'jruby 10.0.0.1 (3.4.2) OpenJDK 64-Bit Server VM [x86_64-linux]')
        end

        it 'pins LC_ALL to C.UTF-8' do
          expect(env).to include('LC_ALL' => 'C.UTF-8')
        end
      end
    end

    context 'when the context was built with an explicit git_ssh' do
      let(:git_ssh) { '/instance/ssh/script' }

      it 'uses the instance git_ssh in preference to the global config' do
        allow(Git::Config.instance).to receive(:git_ssh).and_return('/global/ssh/script')
        expect(env['GIT_SSH']).to eq('/instance/ssh/script')
      end
    end

    context 'when the context was built with git_ssh set to nil' do
      let(:git_ssh) { nil }

      it 'sets GIT_SSH to nil instead of falling back to the global config' do
        allow(Git::Config.instance).to receive(:git_ssh).and_return('/global/ssh/script')
        expect(env).to include('GIT_SSH' => nil)
      end
    end

    context 'when additional overrides add new variables' do
      let(:additional_overrides) { { 'GIT_TRACE' => '1', 'GIT_CURL_VERBOSE' => '1' } }

      it 'merges the new variables while preserving the defaults' do
        expect(env).to include(
          'GIT_TRACE' => '1',
          'GIT_CURL_VERBOSE' => '1',
          'GIT_DIR' => '/fake/repo/.git',
          'GIT_WORK_TREE' => '/fake/repo',
          'GIT_INDEX_FILE' => '/fake/repo/.git/index'
        )
      end
    end

    context 'when additional overrides replace existing variables' do
      let(:additional_overrides) { { 'LC_ALL' => 'C', 'GIT_SSH' => '/custom/ssh' } }

      it 'uses the override values and leaves the other defaults unchanged' do
        expect(env).to include(
          'LC_ALL' => 'C',
          'GIT_SSH' => '/custom/ssh',
          'GIT_DIR' => '/fake/repo/.git',
          'GIT_WORK_TREE' => '/fake/repo'
        )
      end
    end

    context 'when additional overrides set variables to nil' do
      let(:additional_overrides) { { 'GIT_INDEX_FILE' => nil, 'GIT_SSH' => nil } }

      it 'unsets those variables while preserving the other defaults' do
        expect(env).to include(
          'GIT_INDEX_FILE' => nil,
          'GIT_SSH' => nil,
          'GIT_DIR' => '/fake/repo/.git',
          'GIT_WORK_TREE' => '/fake/repo',
          'LC_ALL' => expected_lc_all
        )
      end
    end

    context 'when additional overrides add, override, and exclude simultaneously' do
      let(:additional_overrides) { { 'GIT_TRACE' => '1', 'GIT_INDEX_FILE' => nil, 'LC_ALL' => 'C' } }

      it 'applies every kind of override in a single call' do
        expect(env).to include(
          'GIT_TRACE' => '1',
          'GIT_INDEX_FILE' => nil,
          'LC_ALL' => 'C',
          'GIT_DIR' => '/fake/repo/.git',
          'GIT_WORK_TREE' => '/fake/repo'
        )
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

  describe '#logger' do
    context 'when no logger is provided' do
      it 'returns a Logger instance (null logger)' do
        expect(Git::ExecutionContext::Global.new.logger).to be_a(Logger)
      end
    end

    context 'when a logger is provided' do
      let(:custom_logger) { Logger.new(nil) }

      it 'returns the provided logger' do
        expect(Git::ExecutionContext::Global.new(logger: custom_logger).logger).to be(custom_logger)
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

      it 'passes GIT_EDITOR=true and the platform pinned LC_ALL in the env hash' do
        context.command_capturing('version')
        expect(Git::CommandLine::Capturing).to have_received(:new).with(
          hash_including('GIT_EDITOR' => 'true', 'LC_ALL' => expected_lc_all),
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
          hash_including('GIT_EDITOR' => 'true', 'LC_ALL' => expected_lc_all),
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

    context 'with timeout: keyword' do
      it 'forwards a non-nil timeout to the Version command' do
        allow(version_command_double).to receive(:call)
          .with(timeout: 5)
          .and_return(command_result('git version 2.40.0'))

        context.git_version(timeout: 5)

        expect(version_command_double).to have_received(:call).with(timeout: 5)
      end

      it 'forwards timeout: 0 to the Version command (zero is not nil)' do
        allow(version_command_double).to receive(:call)
          .with(timeout: 0)
          .and_return(command_result('git version 2.40.0'))

        context.git_version(timeout: 0)

        expect(version_command_double).to have_received(:call).with(timeout: 0)
      end

      it 'calls the Version command with no timeout when timeout is nil' do
        allow(version_command_double).to receive(:call)
          .with(no_args)
          .and_return(command_result('git version 2.40.0'))

        context.git_version(timeout: nil)

        expect(version_command_double).to have_received(:call).with(no_args)
      end
    end
  end
end
