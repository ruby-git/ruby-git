# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/diffing'

# Integration coverage for Git::Repository::Diffing:
#   spec/integration/git/repository/diffing_spec.rb covers #diff_full and
#   #diff_numstat, which have facade-owned post-processing.
#   tests/units/test_diff_path_status.rb covers #diff_path_status /
#   #diff_name_status end-to-end (via Git::Base, which delegates to the facade);
#   both methods parse raw diff output via Private.extract_name_status_from_raw.
#   tests/units/test_diff_stats.rb covers #diff_stats, which is a lazy factory
#   delegator (no facade-owned post-processing).

RSpec.describe Git::Repository::Diffing do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  let(:diff_command) { instance_double(Git::Commands::Diff) }

  before do
    allow(Git::Commands::Diff).to receive(:new).with(execution_context).and_return(diff_command)
  end

  describe '#diff_full' do
    subject(:result) { described_instance.diff_full(obj1, obj2, **opts) }

    let(:obj1) { 'HEAD' }
    let(:obj2) { nil }
    let(:opts) { {} }

    let(:patch_text) do
      "diff --git a/lib/foo.rb b/lib/foo.rb\n" \
        "index abc1234..def5678 100644\n" \
        "--- a/lib/foo.rb\n" \
        "+++ b/lib/foo.rb\n" \
        "@@ -1 +1 @@\n" \
        "-old\n" \
        "+new\n"
    end

    let(:diff_result) { command_result(patch_text) }

    context 'when called with default arguments' do
      it 'calls the command with HEAD and patch format options' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end

      it 'returns the patch text extracted from the command output' do
        allow(diff_command).to receive(:call).and_return(diff_result)
        is_expected.to eq(patch_text)
      end
    end

    context 'when called with explicit obj1 and obj2' do
      let(:obj1) { 'abc1234' }
      let(:obj2) { 'def5678' }

      it 'passes both refs as positional arguments to the command' do
        expect(diff_command).to receive(:call).with(
          'abc1234', 'def5678',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end
    end

    context 'when called with only obj1' do
      let(:obj1) { 'abc1234' }

      it 'passes only obj1 as a positional argument to the command' do
        expect(diff_command).to receive(:call).with(
          'abc1234',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter is a single String' do
      let(:opts) { { path_limiter: 'lib/' } }

      it 'wraps the path_limiter in an Array and forwards it to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter is an Array of paths' do
      let(:opts) { { path_limiter: ['lib/', 'spec/'] } }

      it 'forwards the Array as-is to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/', 'spec/']
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter is a Pathname' do
      let(:opts) { { path_limiter: Pathname.new('lib/') } }

      it 'converts the Pathname to a String and forwards it to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter is nil' do
      let(:opts) { { path_limiter: nil } }

      it 'sends path: nil to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter is an empty String' do
      let(:opts) { { path_limiter: '' } }

      it 'normalizes to nil and sends path: nil to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end
    end

    context 'when obj1 is nil and obj2 is nil' do
      let(:obj1) { nil }

      it 'passes no positional arguments to the command' do
        expect(diff_command).to receive(:call).with(
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end
    end

    context 'when the command output includes numstat/shortstat lines before the patch' do
      let(:combined_output) { "1\t2\tlib/foo.rb\n 1 file changed, 1 insertion(+)\n#{patch_text}" }

      it 'strips the numstat/shortstat lines and returns only the patch text' do
        allow(diff_command).to receive(:call).and_return(command_result(combined_output))
        is_expected.to eq(patch_text)
      end
    end

    context 'when the command output does not contain "diff --git" (no changes)' do
      it 'returns the output unchanged' do
        allow(diff_command).to receive(:call).and_return(command_result(''))
        is_expected.to eq('')
      end
    end

    context 'when an unknown option is provided' do
      let(:opts) { { bogus: true } }

      it 'raises an ArgumentError naming the unknown key' do
        expect { subject }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end

    context 'when path_limiter contains an invalid type' do
      let(:opts) { { path_limiter: 123 } }

      it 'raises an ArgumentError naming the path limiter' do
        expect { subject }.to raise_error(ArgumentError, /Invalid path limiter/)
      end
    end

    context 'when obj1 is nil but obj2 is not' do
      let(:obj1) { nil }
      let(:obj2) { 'def5678' }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, /obj1 is nil but obj2 is not/)
      end
    end
  end

  describe '#diff_numstat' do
    subject(:result) { described_instance.diff_numstat(obj1, obj2, **opts) }

    let(:obj1) { 'HEAD' }
    let(:obj2) { nil }
    let(:opts) { {} }

    # Multi-file numstat stdout fixture; includes an empty line between numstat
    # entries to verify that blank lines in command output are handled correctly.
    let(:numstat_stdout) do
      "5\t2\tlib/foo.rb\n\n3\t1\tlib/bar.rb\n 2 files changed, 8 insertions(+), 3 deletions(-)\n"
    end

    let(:diff_result) { command_result(numstat_stdout) }

    context 'when called with default arguments' do
      it 'calls the command with HEAD and numstat format options' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end

      it 'returns a hash with per-file stats and aggregated totals' do
        allow(diff_command).to receive(:call).and_return(diff_result)
        is_expected.to eq(
          total: { insertions: 8, deletions: 3, lines: 11, files: 2 },
          files: {
            'lib/foo.rb' => { insertions: 5, deletions: 2 },
            'lib/bar.rb' => { insertions: 3, deletions: 1 }
          }
        )
      end
    end

    context 'when called with explicit obj1 and obj2' do
      let(:obj1) { 'abc1234' }
      let(:obj2) { 'def5678' }

      it 'passes both refs as positional arguments to the command' do
        expect(diff_command).to receive(:call).with(
          'abc1234', 'def5678',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end
    end

    context 'when called with only obj1' do
      let(:obj1) { 'abc1234' }

      it 'passes only obj1 as a positional argument to the command' do
        expect(diff_command).to receive(:call).with(
          'abc1234',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter is a single String' do
      let(:opts) { { path_limiter: 'lib/' } }

      it 'wraps the path_limiter in an Array and forwards it to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter is an Array of paths' do
      let(:opts) { { path_limiter: ['lib/', 'spec/'] } }

      it 'forwards the Array as-is to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/', 'spec/']
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter is a Pathname' do
      let(:opts) { { path_limiter: Pathname.new('lib/') } }

      it 'converts the Pathname to a String and forwards it to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter is nil' do
      let(:opts) { { path_limiter: nil } }

      it 'sends path: nil to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter is an empty String' do
      let(:opts) { { path_limiter: '' } }

      it 'normalizes to nil and sends path: nil to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end
    end

    context 'when obj1 is nil and obj2 is nil' do
      let(:obj1) { nil }

      it 'passes no positional arguments to the command' do
        expect(diff_command).to receive(:call).with(
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end
    end

    context 'when the command output is empty (no changed files)' do
      it 'returns zero totals and an empty files hash' do
        allow(diff_command).to receive(:call).and_return(command_result(''))
        is_expected.to eq(
          total: { insertions: 0, deletions: 0, lines: 0, files: 0 },
          files: {}
        )
      end
    end

    context 'when the numstat output contains a git-quoted non-ASCII path' do
      # Git quotes paths with non-ASCII characters, escaping each byte in octal.
      # "\\303\\251" is the git octal encoding of "é" (U+00E9, UTF-8: 0xC3 0xA9).
      let(:quoted_stdout) do
        "5\t2\t\"\\303\\251tat.rb\"\n 1 file changed, 5 insertions(+), 2 deletions(-)\n"
      end

      it 'unescapes the git-quoted path in the returned files hash' do
        allow(diff_command).to receive(:call).and_return(command_result(quoted_stdout))
        expect(result[:files]).to have_key('état.rb')
      end
    end

    context 'when an unknown option is provided' do
      let(:opts) { { bogus: true } }

      it 'raises an ArgumentError naming the unknown key' do
        expect { subject }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end

    context 'when path_limiter contains an invalid type' do
      let(:opts) { { path_limiter: 123 } }

      it 'raises an ArgumentError naming the path limiter' do
        expect { subject }.to raise_error(ArgumentError, /Invalid path limiter/)
      end
    end

    context 'when obj1 is nil but obj2 is not' do
      let(:obj1) { nil }
      let(:obj2) { 'def5678' }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, /obj1 is nil but obj2 is not/)
      end
    end
  end

  describe '#diff_path_status' do
    subject(:result) { described_instance.diff_path_status(from, to, **opts) }

    let(:from) { 'HEAD' }
    let(:to) { nil }
    let(:opts) { {} }

    let(:raw_output) do
      ":100644 100644 abc1234 def5678 M\tlib/foo.rb\n" \
        ":000000 100644 0000000 abc1234 A\tREADME.md\n"
    end

    let(:diff_result) { command_result(raw_output) }

    context 'when called with default arguments' do
      it 'calls the command with the default ref and raw format options' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end

      it 'returns a Git::DiffPathStatus with the parsed name-status data' do
        allow(diff_command).to receive(:call).and_return(diff_result)
        expect(result).to be_a(Git::DiffPathStatus)
        expect(result.to_h).to eq('lib/foo.rb' => 'M', 'README.md' => 'A')
      end
    end

    context 'when called with explicit from and to refs' do
      let(:from) { 'abc1234' }
      let(:to) { 'def5678' }

      it 'passes both refs as positional arguments to the command' do
        expect(diff_command).to receive(:call).with(
          'abc1234', 'def5678',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end
    end

    context 'when called with only the from ref' do
      let(:from) { 'abc1234' }

      it 'passes only the from ref as a positional argument to the command' do
        expect(diff_command).to receive(:call).with(
          'abc1234',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter is a single String' do
      let(:opts) { { path_limiter: 'lib/' } }

      it 'wraps the path_limiter in an Array and forwards it to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter is an Array of paths' do
      let(:opts) { { path_limiter: ['lib/', 'spec/'] } }

      it 'forwards the Array as-is to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/', 'spec/']
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter is a Pathname' do
      let(:opts) { { path_limiter: Pathname.new('lib/') } }

      it 'converts the Pathname to a String and forwards it to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter is nil' do
      let(:opts) { { path_limiter: nil } }

      it 'sends path: nil to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter is an empty String' do
      let(:opts) { { path_limiter: '' } }

      it 'normalizes to nil and sends path: nil to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end
    end

    context 'when the raw output contains a rename' do
      let(:rename_output) do
        ":100644 100644 abc1234 def5678 R100\told.rb\tnew.rb\n"
      end

      it 'uses the destination path as the key' do
        allow(diff_command).to receive(:call).and_return(command_result(rename_output))
        expect(result.to_h).to eq('new.rb' => 'R100')
      end
    end

    context 'when the raw output contains non-raw-diff header lines' do
      let(:mixed_output) do
        "1\t0\tlib/foo.rb\n" \
          ":100644 100644 abc1234 def5678 M\tlib/foo.rb\n"
      end

      it 'skips non-raw-diff lines and parses only raw-diff lines' do
        allow(diff_command).to receive(:call).and_return(command_result(mixed_output))
        expect(result.to_h).to eq('lib/foo.rb' => 'M')
      end
    end

    context 'when the raw output contains a git-quoted path' do
      let(:quoted_output) { ":000000 100644 0000000 abc1234 A\t\"new_file.rb\"\n" }

      it 'unescapes the git-quoted path' do
        allow(diff_command).to receive(:call).and_return(command_result(quoted_output))
        expect(result.to_h).to eq('new_file.rb' => 'A')
      end
    end

    context 'when from is nil and to is nil' do
      let(:from) { nil }

      it 'passes no positional arguments to the command' do
        expect(diff_command).to receive(:call).with(
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        subject
      end
    end

    context 'when an unknown option is provided' do
      let(:opts) { { bogus: true } }

      it 'raises an ArgumentError naming the unknown key' do
        expect { subject }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end

    context 'when the deprecated :path option is provided' do
      let(:opts) { { path: 'lib/' } }

      before do
        allow(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        allow(Git::Deprecation).to receive(:warn)
      end

      it 'emits a deprecation warning naming the facade method' do
        expect(Git::Deprecation).to receive(:warn).with(
          'Git::Repository#diff_path_status :path option is deprecated. Use :path_limiter instead.'
        )
        subject
      end

      it 'uses the :path value as the path limiter' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        subject
      end
    end

    context 'when both :path_limiter and :path are provided' do
      let(:opts) { { path_limiter: 'lib/', path: 'other/' } }

      it 'uses :path_limiter and does not emit a deprecation warning' do
        expect(Git::Deprecation).not_to receive(:warn)
        expect(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        subject
      end
    end

    context 'when path_limiter contains an invalid type' do
      let(:opts) { { path_limiter: 123 } }

      it 'raises an ArgumentError naming the path limiter' do
        expect { subject }.to raise_error(ArgumentError, /Invalid path limiter/)
      end
    end

    context 'when from is nil but to is not' do
      let(:from) { nil }
      let(:to) { 'def5678' }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, /`from` is nil but `to` is not/)
      end
    end
  end

  describe '#diff_name_status' do
    subject(:result) { described_instance.diff_name_status }

    let(:raw_output) { ":100644 100644 abc1234 def5678 M\tlib/foo.rb\n" }
    let(:diff_result) { command_result(raw_output) }

    it 'delegates to the diff command with the default ref and raw format options' do
      expect(diff_command).to receive(:call).with(
        'HEAD',
        raw: true, numstat: true, shortstat: true,
        src_prefix: 'a/', dst_prefix: 'b/',
        path: nil
      ).and_return(diff_result)
      subject
    end

    it 'returns a Git::DiffPathStatus' do
      allow(diff_command).to receive(:call).and_return(diff_result)
      expect(result).to be_a(Git::DiffPathStatus)
    end
  end

  describe '#diff_stats' do
    subject(:result) { described_instance.diff_stats(obj1, obj2, **opts) }

    let(:obj1) { 'HEAD' }
    let(:obj2) { nil }
    let(:opts) { {} }

    let(:diff_stats_instance) { instance_double(Git::DiffStats) }

    context 'when called with default arguments' do
      it 'constructs a Git::DiffStats with self, HEAD, nil, and no path limiter' do
        expect(Git::DiffStats).to receive(:new)
          .with(described_instance, 'HEAD', nil, nil)
          .and_return(diff_stats_instance)
        subject
      end

      it 'returns the Git::DiffStats instance' do
        allow(Git::DiffStats).to receive(:new).and_return(diff_stats_instance)
        is_expected.to be(diff_stats_instance)
      end
    end

    context 'when called with explicit obj1 and obj2' do
      let(:obj1) { 'abc1234' }
      let(:obj2) { 'def5678' }

      it 'passes both refs to Git::DiffStats.new' do
        expect(Git::DiffStats).to receive(:new)
          .with(described_instance, 'abc1234', 'def5678', nil)
          .and_return(diff_stats_instance)
        subject
      end
    end

    context 'when called with only obj1' do
      let(:obj1) { 'abc1234' }

      it 'passes obj1 and nil as obj2 to Git::DiffStats.new' do
        expect(Git::DiffStats).to receive(:new)
          .with(described_instance, 'abc1234', nil, nil)
          .and_return(diff_stats_instance)
        subject
      end
    end

    context 'when path_limiter is a String' do
      let(:opts) { { path_limiter: 'lib/' } }

      it 'passes the path_limiter to Git::DiffStats.new' do
        expect(Git::DiffStats).to receive(:new)
          .with(described_instance, 'HEAD', nil, 'lib/')
          .and_return(diff_stats_instance)
        subject
      end
    end

    context 'when path_limiter is nil' do
      let(:opts) { { path_limiter: nil } }

      it 'passes nil as path_limiter to Git::DiffStats.new' do
        expect(Git::DiffStats).to receive(:new)
          .with(described_instance, 'HEAD', nil, nil)
          .and_return(diff_stats_instance)
        subject
      end
    end

    context 'when obj1 is nil and obj2 is nil' do
      let(:obj1) { nil }

      it 'constructs Git::DiffStats with self, nil, nil, and no path limiter' do
        expect(Git::DiffStats).to receive(:new)
          .with(described_instance, nil, nil, nil)
          .and_return(diff_stats_instance)
        subject
      end
    end

    context 'when an unknown option is provided' do
      let(:opts) { { bogus: true } }

      it 'raises an ArgumentError naming the unknown key' do
        expect { subject }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end

    context 'when obj1 is nil but obj2 is not' do
      let(:obj1) { nil }
      let(:obj2) { 'def5678' }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, /obj1 is nil but obj2 is not/)
      end
    end
  end

  describe '#diff' do
    subject(:result) { described_instance.diff(obj1, obj2) }

    let(:obj1) { 'HEAD' }
    let(:obj2) { nil }

    let(:diff_instance) { instance_double(Git::Diff) }

    context 'when called with default arguments' do
      it 'constructs a Git::Diff with self, HEAD, and nil' do
        expect(Git::Diff).to receive(:new)
          .with(described_instance, 'HEAD', nil)
          .and_return(diff_instance)
        subject
      end

      it 'returns the Git::Diff instance' do
        allow(Git::Diff).to receive(:new).and_return(diff_instance)
        is_expected.to be(diff_instance)
      end
    end

    context 'when called with explicit obj1 and obj2' do
      let(:obj1) { 'abc1234' }
      let(:obj2) { 'def5678' }

      it 'passes both refs to Git::Diff.new' do
        expect(Git::Diff).to receive(:new)
          .with(described_instance, 'abc1234', 'def5678')
          .and_return(diff_instance)
        subject
      end
    end

    context 'when called with only obj1' do
      let(:obj1) { 'abc1234' }

      it 'passes obj1 and nil as obj2 to Git::Diff.new' do
        expect(Git::Diff).to receive(:new)
          .with(described_instance, 'abc1234', nil)
          .and_return(diff_instance)
        subject
      end
    end

    context 'when called with nil obj1' do
      let(:obj1) { nil }

      it 'constructs Git::Diff with self, nil, and nil' do
        expect(Git::Diff).to receive(:new)
          .with(described_instance, nil, nil)
          .and_return(diff_instance)
        subject
      end
    end
  end
end
