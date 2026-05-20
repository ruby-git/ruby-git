# frozen_string_literal: true

require 'spec_helper'
require 'git/diff_stats'
require 'git/repository'
require 'git/repository/diffing'

# Integration coverage for Git::Repository::Diffing:
#   spec/integration/git/repository/diffing_spec.rb covers #diff_full, which
#   has facade-owned post-processing (extract_patch_text strips numstat/shortstat
#   lines before returning the patch text).
#   tests/units/test_diff_path_status.rb covers diff_path_status / diff_name_status,
#   which are pure single-command delegators with no post-processing.
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
      before do
        allow(diff_command).to receive(:call).with(
          'HEAD',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
      end

      it 'calls the command with HEAD and patch format options' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        described_instance.diff_full
      end

      it 'returns the patch text extracted from the command output' do
        expect(described_instance.diff_full).to eq(patch_text)
      end
    end

    context 'when called with explicit obj1 and obj2' do
      it 'passes both refs as positional arguments to the command' do
        expect(diff_command).to receive(:call).with(
          'abc1234', 'def5678',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        described_instance.diff_full('abc1234', 'def5678')
      end
    end

    context 'when called with only obj1' do
      it 'passes only obj1 as a positional argument to the command' do
        expect(diff_command).to receive(:call).with(
          'abc1234',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        described_instance.diff_full('abc1234')
      end
    end

    context 'when path_limiter is a single String' do
      it 'wraps the path_limiter in an Array and forwards it to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        described_instance.diff_full('HEAD', nil, path_limiter: 'lib/')
      end
    end

    context 'when path_limiter is an Array of paths' do
      it 'forwards the Array as-is to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/', 'spec/']
        ).and_return(diff_result)
        described_instance.diff_full('HEAD', nil, path_limiter: ['lib/', 'spec/'])
      end
    end

    context 'when path_limiter is a Pathname' do
      it 'converts the Pathname to a String and forwards it to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        described_instance.diff_full('HEAD', nil, path_limiter: Pathname.new('lib/'))
      end
    end

    context 'when path_limiter is nil' do
      it 'sends path: nil to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        described_instance.diff_full('HEAD', nil, path_limiter: nil)
      end
    end

    context 'when path_limiter is an empty String' do
      it 'normalizes to nil and sends path: nil to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        described_instance.diff_full('HEAD', nil, path_limiter: '')
      end
    end

    context 'when path_limiter contains an invalid type' do
      it 'raises an ArgumentError naming the path limiter' do
        expect { described_instance.diff_full('HEAD', nil, path_limiter: 123) }
          .to raise_error(ArgumentError, /Invalid path limiter/)
      end
    end

    context 'when obj1 is nil but obj2 is not' do
      it 'raises an ArgumentError' do
        expect { described_instance.diff_full(nil, 'def5678') }
          .to raise_error(ArgumentError, /obj1 is nil but obj2 is not/)
      end
    end

    context 'when an unknown option is provided' do
      it 'raises an ArgumentError naming the unknown key' do
        expect { described_instance.diff_full('HEAD', nil, bogus: true) }
          .to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end

    context 'when the command output includes numstat/shortstat lines before the patch' do
      let(:combined_output) { "1\t2\tlib/foo.rb\n 1 file changed, 1 insertion(+)\n#{patch_text}" }
      let(:diff_result) { command_result(combined_output) }

      before do
        allow(diff_command).to receive(:call).with(
          'HEAD',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
      end

      it 'strips the numstat/shortstat lines and returns only the patch text' do
        expect(described_instance.diff_full).to eq(patch_text)
      end
    end

    context 'when the command output does not contain "diff --git" (no changes)' do
      let(:diff_result) { command_result('') }

      before do
        allow(diff_command).to receive(:call).with(
          'HEAD',
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
      end

      it 'returns the output unchanged' do
        expect(described_instance.diff_full).to eq('')
      end
    end
  end

  describe '#diff_numstat' do
    # Multi-file numstat stdout fixture; includes an empty line between numstat
    # entries to exercise the l.empty? branch inside extract_numstat_lines.
    let(:numstat_stdout) do
      "5\t2\tlib/foo.rb\n\n3\t1\tlib/bar.rb\n 2 files changed, 8 insertions(+), 3 deletions(-)\n"
    end

    let(:diff_numstat_result) { command_result(numstat_stdout) }

    context 'when called with default arguments' do
      it 'calls the command with HEAD and numstat format options' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_numstat_result)
        described_instance.diff_numstat
      end

      it 'returns a hash with per-file stats and aggregated totals' do
        allow(diff_command).to receive(:call).with(
          'HEAD',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_numstat_result)
        expect(described_instance.diff_numstat).to eq(
          total: { insertions: 8, deletions: 3, lines: 11, files: 2 },
          files: {
            'lib/foo.rb' => { insertions: 5, deletions: 2 },
            'lib/bar.rb' => { insertions: 3, deletions: 1 }
          }
        )
      end
    end

    context 'when called with explicit obj1 and obj2' do
      it 'passes both refs as positional arguments to the command' do
        expect(diff_command).to receive(:call).with(
          'abc1234', 'def5678',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_numstat_result)
        described_instance.diff_numstat('abc1234', 'def5678')
      end
    end

    context 'when called with only obj1' do
      it 'passes only obj1 as a positional argument to the command' do
        expect(diff_command).to receive(:call).with(
          'abc1234',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_numstat_result)
        described_instance.diff_numstat('abc1234')
      end
    end

    context 'when path_limiter is a single String' do
      it 'wraps the path_limiter in an Array and forwards it to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_numstat_result)
        described_instance.diff_numstat('HEAD', nil, path_limiter: 'lib/')
      end
    end

    context 'when path_limiter is an Array of paths' do
      it 'forwards the Array as-is to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/', 'spec/']
        ).and_return(diff_numstat_result)
        described_instance.diff_numstat('HEAD', nil, path_limiter: ['lib/', 'spec/'])
      end
    end

    context 'when path_limiter is a Pathname' do
      it 'converts the Pathname to a String and forwards it to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_numstat_result)
        described_instance.diff_numstat('HEAD', nil, path_limiter: Pathname.new('lib/'))
      end
    end

    context 'when path_limiter is nil' do
      it 'sends path: nil to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_numstat_result)
        described_instance.diff_numstat('HEAD', nil, path_limiter: nil)
      end
    end

    context 'when path_limiter is an empty String' do
      it 'normalizes to nil and sends path: nil to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_numstat_result)
        described_instance.diff_numstat('HEAD', nil, path_limiter: '')
      end
    end

    context 'when an unknown option is provided' do
      it 'raises an ArgumentError naming the unknown key' do
        expect { described_instance.diff_numstat('HEAD', nil, bogus: true) }
          .to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end

    context 'when obj1 is nil but obj2 is not' do
      it 'raises an ArgumentError' do
        expect { described_instance.diff_numstat(nil, 'def5678') }
          .to raise_error(ArgumentError, /obj1 is nil but obj2 is not/)
      end
    end

    context 'when the command output is empty (no changed files)' do
      let(:diff_numstat_result) { command_result('') }

      before do
        allow(diff_command).to receive(:call).with(
          'HEAD',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_numstat_result)
      end

      it 'returns zero totals and an empty files hash' do
        expect(described_instance.diff_numstat).to eq(
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
      let(:diff_numstat_result) { command_result(quoted_stdout) }

      before do
        allow(diff_command).to receive(:call).with(
          'HEAD',
          numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_numstat_result)
      end

      it 'unescapes the git-quoted path in the returned files hash' do
        result = described_instance.diff_numstat
        expect(result[:files]).to have_key('état.rb')
      end
    end
  end

  describe '#diff_path_status' do
    let(:raw_output) do
      ":100644 100644 abc1234 def5678 M\tlib/foo.rb\n" \
        ":000000 100644 0000000 abc1234 A\tREADME.md\n"
    end

    let(:diff_result) { command_result(raw_output) }

    context 'when called with default arguments' do
      before do
        allow(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
      end

      it 'calls the command with the default ref and raw format options' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        described_instance.diff_path_status
      end

      it 'returns a Git::DiffPathStatus with the parsed name-status data' do
        result = described_instance.diff_path_status
        expect(result).to be_a(Git::DiffPathStatus)
        expect(result.to_h).to eq('lib/foo.rb' => 'M', 'README.md' => 'A')
      end
    end

    context 'when called with explicit from and to refs' do
      it 'passes both refs as positional arguments to the command' do
        expect(diff_command).to receive(:call).with(
          'abc1234', 'def5678',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        described_instance.diff_path_status('abc1234', 'def5678')
      end
    end

    context 'when called with only the from ref' do
      it 'passes only the from ref as a positional argument to the command' do
        expect(diff_command).to receive(:call).with(
          'abc1234',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
        described_instance.diff_path_status('abc1234')
      end
    end

    context 'when path_limiter is a single String' do
      it 'wraps the path_limiter in an Array and forwards it to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        described_instance.diff_path_status('HEAD', nil, path_limiter: 'lib/')
      end
    end

    context 'when path_limiter is an Array of paths' do
      it 'forwards the Array as-is to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/', 'spec/']
        ).and_return(diff_result)
        described_instance.diff_path_status('HEAD', nil, path_limiter: ['lib/', 'spec/'])
      end
    end

    context 'when path_limiter is a Pathname' do
      it 'converts the Pathname to a String and forwards it to the command' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        described_instance.diff_path_status('HEAD', nil, path_limiter: Pathname.new('lib/'))
      end
    end

    context 'when the deprecated :path option is provided' do
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
        described_instance.diff_path_status('HEAD', nil, path: 'lib/')
      end

      it 'uses the :path value as the path limiter' do
        expect(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        described_instance.diff_path_status('HEAD', nil, path: 'lib/')
      end
    end

    context 'when both :path_limiter and :path are provided' do
      it 'uses :path_limiter and does not emit a deprecation warning' do
        expect(Git::Deprecation).not_to receive(:warn)
        expect(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        described_instance.diff_path_status('HEAD', nil, path_limiter: 'lib/', path: 'other/')
      end
    end

    context 'when an unknown option is provided' do
      it 'raises an ArgumentError naming the unknown key' do
        expect { described_instance.diff_path_status('HEAD', nil, bogus: true) }
          .to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end

    context 'when from is nil but to is not' do
      it 'raises an ArgumentError' do
        expect { described_instance.diff_path_status(nil, 'def5678') }
          .to raise_error(ArgumentError, /`from` is nil but `to` is not/)
      end
    end

    context 'when the raw output contains a rename' do
      let(:rename_output) do
        ":100644 100644 abc1234 def5678 R100\told.rb\tnew.rb\n"
      end
      let(:diff_result) { command_result(rename_output) }

      before do
        allow(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
      end

      it 'uses the destination path as the key' do
        result = described_instance.diff_path_status
        expect(result.to_h).to eq('new.rb' => 'R100')
      end
    end

    context 'when the raw output contains non-raw-diff header lines' do
      let(:mixed_output) do
        "1\t0\tlib/foo.rb\n" \
          ":100644 100644 abc1234 def5678 M\tlib/foo.rb\n"
      end
      let(:diff_result) { command_result(mixed_output) }

      before do
        allow(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
      end

      it 'skips non-raw-diff lines and parses only raw-diff lines' do
        result = described_instance.diff_path_status
        expect(result.to_h).to eq('lib/foo.rb' => 'M')
      end
    end

    context 'when the raw output contains a git-quoted path' do
      let(:quoted_output) { ":000000 100644 0000000 abc1234 A\t\"new_file.rb\"\n" }
      let(:diff_result) { command_result(quoted_output) }

      before do
        allow(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
      end

      it 'unescapes the git-quoted path' do
        result = described_instance.diff_path_status
        expect(result.to_h).to eq('new_file.rb' => 'A')
      end
    end
  end

  describe '#diff_name_status' do
    it 'returns the same result as diff_path_status when called with the same arguments' do
      allow(diff_command).to receive(:call).and_return(command_result)
      expect(described_instance.diff_name_status.to_h).to eq(
        described_instance.diff_path_status.to_h
      )
    end
  end

  describe '#diff_stats' do
    let(:diff_stats_instance) { instance_double(Git::DiffStats) }

    context 'when called with default arguments' do
      before do
        allow(Git::DiffStats).to receive(:new).and_return(diff_stats_instance)
      end

      it 'constructs a Git::DiffStats with self, HEAD, nil, and no path limiter' do
        expect(Git::DiffStats).to receive(:new)
          .with(described_instance, 'HEAD', nil, nil)
          .and_return(diff_stats_instance)
        described_instance.diff_stats
      end

      it 'returns the Git::DiffStats instance' do
        expect(described_instance.diff_stats).to be(diff_stats_instance)
      end
    end

    context 'when called with explicit obj1 and obj2' do
      it 'passes both refs to Git::DiffStats.new' do
        expect(Git::DiffStats).to receive(:new)
          .with(described_instance, 'abc1234', 'def5678', nil)
          .and_return(diff_stats_instance)
        described_instance.diff_stats('abc1234', 'def5678')
      end
    end

    context 'when called with only obj1' do
      it 'passes obj1 and nil as obj2 to Git::DiffStats.new' do
        expect(Git::DiffStats).to receive(:new)
          .with(described_instance, 'abc1234', nil, nil)
          .and_return(diff_stats_instance)
        described_instance.diff_stats('abc1234')
      end
    end

    context 'when path_limiter is a String' do
      it 'passes the path_limiter to Git::DiffStats.new' do
        expect(Git::DiffStats).to receive(:new)
          .with(described_instance, 'HEAD', nil, 'lib/')
          .and_return(diff_stats_instance)
        described_instance.diff_stats('HEAD', nil, path_limiter: 'lib/')
      end
    end

    context 'when path_limiter is nil' do
      it 'passes nil as path_limiter to Git::DiffStats.new' do
        expect(Git::DiffStats).to receive(:new)
          .with(described_instance, 'HEAD', nil, nil)
          .and_return(diff_stats_instance)
        described_instance.diff_stats('HEAD', nil, path_limiter: nil)
      end
    end

    context 'when an unknown option is provided' do
      it 'raises an ArgumentError naming the unknown key' do
        expect { described_instance.diff_stats('HEAD', nil, bogus: true) }
          .to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end

    context 'when obj1 is nil but obj2 is not' do
      it 'raises an ArgumentError' do
        expect { described_instance.diff_stats(nil, 'def5678') }
          .to raise_error(ArgumentError, /obj1 is nil but obj2 is not/)
      end
    end
  end
end
