# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/status_operations'

RSpec.describe Git::Repository::StatusOperations do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#ls_files' do
    subject(:result) { described_instance.ls_files(location) }

    let(:location) { nil }
    let(:ls_files_command) { instance_double(Git::Commands::LsFiles) }

    before do
      allow(Git::Commands::LsFiles).to receive(:new).with(execution_context).and_return(ls_files_command)
    end

    context 'when no location is given (nil)' do
      it "delegates to LsFiles#call with '.' as the default location" do
        expect(ls_files_command).to receive(:call).with('.', stage: true).and_return(command_result(''))
        result
      end

      it 'returns an empty hash when git output is empty' do
        allow(ls_files_command).to receive(:call).with('.', stage: true).and_return(command_result(''))
        expect(result).to eq({})
      end
    end

    context 'when an explicit location is given' do
      let(:location) { 'lib/' }

      it 'delegates to LsFiles#call with the given location' do
        expect(ls_files_command).to receive(:call).with('lib/', stage: true).and_return(command_result(''))
        result
      end
    end

    context 'when stdout contains a plain (unquoted) file path' do
      let(:sha) { 'abc1234567890abcdef1234567890abcdef12345678' }
      let(:stdout) { "100644 #{sha} 0\tREADME.md\n" }

      before do
        allow(ls_files_command).to receive(:call).with('.', stage: true).and_return(command_result(stdout))
      end

      it 'returns a hash keyed by the file path' do
        expect(result.keys).to eq(['README.md'])
      end

      it 'includes the correct index metadata for the file' do
        expect(result['README.md']).to eq(path: 'README.md', mode_index: '100644', sha_index: sha, stage: '0')
      end
    end

    context 'when stdout contains a git-quoted (escaped) file path' do
      # Git octal-escapes non-ASCII paths. U+00B5 µ encodes as UTF-8 bytes \302\265.
      let(:sha) { 'abc1234567890abcdef1234567890abcdef12345678' }
      let(:stdout) { "100644 #{sha} 0\t\"\\302\\265.txt\"\n" }

      before do
        allow(ls_files_command).to receive(:call).with('.', stage: true).and_return(command_result(stdout))
      end

      it 'returns the unescaped path as the hash key' do
        expect(result.keys).to eq(['µ.txt'])
      end

      it 'stores the unescaped path in the :path field' do
        expect(result['µ.txt'][:path]).to eq('µ.txt')
      end
    end

    context 'when stdout contains multiple files' do
      let(:sha_a) { 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' }
      let(:sha_b) { 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' }
      let(:stdout) do
        "100644 #{sha_a} 0\ta.rb\n" \
          "100755 #{sha_b} 0\tb.sh\n"
      end

      before do
        allow(ls_files_command).to receive(:call).with('.', stage: true).and_return(command_result(stdout))
      end

      it 'returns an entry for each file' do
        expect(result.keys).to contain_exactly('a.rb', 'b.sh')
      end
    end
  end

  describe '#no_commits?' do
    subject(:result) { described_instance.no_commits? }

    let(:rev_parse_command) { instance_double(Git::Commands::RevParse) }

    before do
      allow(Git::Commands::RevParse).to receive(:new).with(execution_context).and_return(rev_parse_command)
    end

    context 'when the repository has at least one commit' do
      it 'delegates to RevParse#call with HEAD and verify: true' do
        expect(rev_parse_command).to receive(:call).with('HEAD',
                                                         verify: true).and_return(command_result('abc123def456'))
        result
      end

      it 'returns false' do
        allow(rev_parse_command).to receive(:call).with('HEAD', verify: true).and_return(command_result('abc123def456'))
        expect(result).to be(false)
      end
    end

    context 'when the repository has no commits (exit 128 with expected stderr)' do
      let(:failed_result) do
        command_result('', stderr: 'fatal: Needed a single revision', exitstatus: 128)
      end

      before do
        allow(rev_parse_command).to receive(:call).with('HEAD', verify: true)
                                                  .and_raise(Git::FailedError.new(failed_result))
      end

      it 'returns true' do
        expect(result).to be(true)
      end
    end

    context 'when git rev-parse fails for an unrelated reason' do
      let(:failed_result) do
        command_result('', stderr: 'fatal: not a git repository', exitstatus: 128)
      end

      before do
        allow(rev_parse_command).to receive(:call).with('HEAD', verify: true)
                                                  .and_raise(Git::FailedError.new(failed_result))
      end

      it 're-raises the error' do
        expect { described_instance.no_commits? }.to raise_error(Git::FailedError, /not a git repository/)
      end
    end
  end

  describe '#empty?' do
    subject(:result) { described_instance.empty? }

    before do
      allow(described_instance).to receive(:no_commits?).and_return(true)
      allow(Git::Deprecation).to receive(:warn)
    end

    it 'emits a deprecation warning matching /empty\? is deprecated/' do
      expect(Git::Deprecation).to receive(:warn).with(/empty\? is deprecated/)
      result
    end

    it 'delegates to no_commits?' do
      expect(described_instance).to receive(:no_commits?).and_return(true)
      result
    end

    it 'returns the return value of no_commits?' do
      allow(described_instance).to receive(:no_commits?).and_return(false)
      expect(result).to be(false)
    end
  end

  describe '#untracked_files' do
    subject(:result) { described_instance.untracked_files }

    let(:work_dir) { '/path/to/work_dir' }
    let(:ls_files_command) { instance_double(Git::Commands::LsFiles) }

    before do
      allow(Git::Commands::LsFiles).to receive(:new).with(execution_context).and_return(ls_files_command)
      allow(execution_context).to receive(:git_work_dir).and_return(work_dir)
    end

    it 'delegates to LsFiles#call with others: true, exclude_standard: true, and chdir from git_work_dir' do
      expect(ls_files_command).to receive(:call).with(
        others: true, exclude_standard: true, chdir: work_dir
      ).and_return(command_result(''))
      result
    end

    context 'when there are no untracked files (empty stdout)' do
      it 'returns an empty array' do
        allow(ls_files_command).to receive(:call).with(
          others: true, exclude_standard: true, chdir: work_dir
        ).and_return(command_result(''))
        expect(result).to eq([])
      end
    end

    context 'when there is one untracked file' do
      it 'returns an array containing that filename' do
        allow(ls_files_command).to receive(:call).with(
          others: true, exclude_standard: true, chdir: work_dir
        ).and_return(command_result("new_feature.rb\n"))
        expect(result).to eq(['new_feature.rb'])
      end
    end

    context 'when there are multiple untracked files' do
      it 'returns an array of all filenames' do
        allow(ls_files_command).to receive(:call).with(
          others: true, exclude_standard: true, chdir: work_dir
        ).and_return(command_result("a.rb\nb.rb\ntmp/debug.log\n"))
        expect(result).to eq(['a.rb', 'b.rb', 'tmp/debug.log'])
      end
    end

    context 'when stdout contains a git-quoted (non-ASCII) path' do
      it 'returns the unescaped path' do
        # U+00B5 µ encodes as UTF-8 bytes \302\265
        allow(ls_files_command).to receive(:call).with(
          others: true, exclude_standard: true, chdir: work_dir
        ).and_return(command_result("\"\\302\\265.txt\"\n"))
        expect(result).to eq(['µ.txt'])
      end
    end

    context 'when git_work_dir is nil (bare repository or no working tree)' do
      let(:work_dir) { nil }

      it 'passes chdir: nil to the command' do
        expect(ls_files_command).to receive(:call).with(
          others: true, exclude_standard: true, chdir: nil
        ).and_return(command_result(''))
        result
      end
    end
  end

  describe '#status' do
    subject(:result) { described_instance.status }

    let(:status) { instance_double(Git::Status) }

    before do
      allow(Git::Status).to receive(:new).with(described_instance).and_return(status)
    end

    it 'constructs Git::Status with the repository instance as the base' do
      expect(Git::Status).to receive(:new).with(described_instance).and_return(status)
      result
    end

    it 'returns the Git::Status instance' do
      expect(result).to eq(status)
    end
  end
end
