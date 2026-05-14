# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/diffing'

# Integration-level coverage for Git::Repository::Diffing facade methods is
# provided by the existing Test::Unit integration tests:
#   tests/units/test_diff_path_status.rb   (diff_path_status / diff_name_status)
# Each facade method delegates to Git::Commands::Diff with no multi-command
# orchestration. The unit specs below cover each facade method's own behavior;
# the integration tests cover end-to-end git execution.

RSpec.describe Git::Repository::Diffing do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  let(:diff_command) { instance_double(Git::Commands::Diff) }

  before do
    allow(Git::Commands::Diff).to receive(:new).with(execution_context).and_return(diff_command)
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

      it 'constructs Git::Commands::Diff with the execution context' do
        expect(Git::Commands::Diff).to receive(:new).with(execution_context).and_return(diff_command)
        allow(diff_command).to receive(:call).and_return(diff_result)
        described_instance.diff_path_status
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

      it 'returns a Git::DiffPathStatus' do
        expect(described_instance.diff_path_status).to be_a(Git::DiffPathStatus)
      end

      it 'returns a Git::DiffPathStatus with the parsed name-status data' do
        result = described_instance.diff_path_status
        expect(result.to_h).to eq('lib/foo.rb' => 'M', 'README.md' => 'A')
      end
    end

    context 'when called with explicit from and to refs' do
      before do
        allow(diff_command).to receive(:call).with(
          'abc1234', 'def5678',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
      end

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
      before do
        allow(diff_command).to receive(:call).with(
          'abc1234',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(diff_result)
      end

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
      before do
        allow(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
      end

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
      before do
        allow(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/', 'spec/']
        ).and_return(diff_result)
      end

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
      before do
        allow(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: ['lib/']
        ).and_return(diff_result)
        allow(Git::Deprecation).to receive(:warn)
      end

      it 'uses :path_limiter and does not emit a deprecation warning' do
        expect(Git::Deprecation).not_to receive(:warn)
        described_instance.diff_path_status('HEAD', nil, path_limiter: 'lib/', path: 'other/')
      end
    end

    context 'when an unknown option is provided' do
      it 'raises an ArgumentError' do
        expect { described_instance.diff_path_status('HEAD', nil, bogus: true) }
          .to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end

    context 'when from starts with a dash' do
      it 'raises an ArgumentError' do
        expect { described_instance.diff_path_status('-bad-ref') }
          .to raise_error(ArgumentError, /Invalid argument/)
      end
    end

    context 'when to starts with a dash' do
      it 'raises an ArgumentError' do
        expect { described_instance.diff_path_status('HEAD', '-bad-ref') }
          .to raise_error(ArgumentError, /Invalid argument/)
      end
    end

    context 'when the raw output contains a rename' do
      let(:rename_output) do
        ":100644 100644 abc1234 def5678 R100\told.rb\tnew.rb\n"
      end

      before do
        allow(diff_command).to receive(:call).with(
          'HEAD',
          raw: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: nil
        ).and_return(command_result(rename_output))
      end

      it 'uses the destination path as the key' do
        result = described_instance.diff_path_status
        expect(result.to_h).to eq('new.rb' => 'R100')
      end
    end
  end

  describe '#diff_name_status' do
    it 'is an alias for diff_path_status' do
      expect(described_instance.method(:diff_name_status)).to eq(described_instance.method(:diff_path_status))
    end
  end
end
