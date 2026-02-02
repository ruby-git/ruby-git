# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/list'

RSpec.describe Git::Commands::Branch::List do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # Format string used by the command
  let(:format_string) { described_class::FORMAT_STRING }

  # Helper to build expected command arguments
  def expected_args(*extra_args)
    ['branch', '--list', "--format=#{format_string}", *extra_args]
  end

  # Helper to expect command call - verifies the command is called with specific arguments
  def expect_command(*args, stdout: '')
    expect(execution_context).to receive(:command).with(*args, any_args).and_return(command_result(stdout))
  end

  # Helper to stub command call for parsing tests where other expectations do the verification
  def allow_command(*args, stdout: '')
    allow(execution_context).to receive(:command).with(*args, any_args).and_return(command_result(stdout))
  end

  describe '#call' do
    context 'with no options (basic list)' do
      it 'calls git branch --list with format string' do
        expect_command(*expected_args)
        command.call
      end
    end

    context 'with :all option' do
      it 'adds -a flag' do
        expect_command(*expected_args('-a'))
        command.call(all: true)
      end
    end

    context 'with :remotes option' do
      it 'adds -r flag' do
        expect_command(*expected_args('-r'))
        command.call(remotes: true)
      end
    end

    context 'with :sort option' do
      it 'adds --sort=<key> with single value' do
        expect_command(*expected_args('--sort=refname'))
        command.call(sort: 'refname')
      end

      it 'adds multiple --sort=<key> with array of values' do
        expect_command(*expected_args('--sort=refname', '--sort=-committerdate'))
        command.call(sort: ['refname', '-committerdate'])
      end
    end

    context 'with :ignore_case option' do
      it 'adds --ignore-case flag' do
        expect_command(*expected_args('--ignore-case'))
        command.call(ignore_case: true)
      end
    end

    context 'with :contains option' do
      it 'adds --contains <commit> with string value' do
        expect_command(*expected_args('--contains', 'abc123'))
        command.call(contains: 'abc123')
      end

      it 'adds --contains flag with true (defaults to HEAD)' do
        expect_command(*expected_args('--contains'))
        command.call(contains: true)
      end
    end

    context 'with :no_contains option' do
      it 'adds --no-contains <commit> with string value' do
        expect_command(*expected_args('--no-contains', 'abc123'))
        command.call(no_contains: 'abc123')
      end

      it 'adds --no-contains flag with true (defaults to HEAD)' do
        expect_command(*expected_args('--no-contains'))
        command.call(no_contains: true)
      end
    end

    context 'with :merged option' do
      it 'adds --merged <commit> with string value' do
        expect_command(*expected_args('--merged', 'main'))
        command.call(merged: 'main')
      end

      it 'adds --merged flag with true (defaults to HEAD)' do
        expect_command(*expected_args('--merged'))
        command.call(merged: true)
      end
    end

    context 'with :no_merged option' do
      it 'adds --no-merged <commit> with string value' do
        expect_command(*expected_args('--no-merged', 'main'))
        command.call(no_merged: 'main')
      end

      it 'adds --no-merged flag with true (defaults to HEAD)' do
        expect_command(*expected_args('--no-merged'))
        command.call(no_merged: true)
      end
    end

    context 'with :points_at option' do
      it 'adds --points-at <object>' do
        expect_command(*expected_args('--points-at', 'v1.0'))
        command.call(points_at: 'v1.0')
      end
    end

    context 'with patterns' do
      it 'adds pattern arguments' do
        expect_command(*expected_args('feature/*'))
        command.call('feature/*')
      end

      it 'adds multiple pattern arguments' do
        expect_command(*expected_args('feature/*', 'bugfix/*'))
        command.call('feature/*', 'bugfix/*')
      end
    end

    context 'with multiple options' do
      it 'combines flags correctly' do
        expect_command(*expected_args('-a', '--sort=refname', '--contains', 'abc123'))
        command.call(all: true, sort: 'refname', contains: 'abc123')
      end
    end

    context 'when parsing formatted branch output' do
      # Format: refname|objectname|HEAD|worktreepath|symref|upstream
      let(:format_output) do
        [
          'refs/heads/main|abc123def456789012345678901234567890abcd|*|||refs/remotes/origin/main',
          'refs/heads/feature-branch|def456789012345678901234567890abcdef12||||',
          'refs/remotes/origin/main|abc123def456789012345678901234567890abcd||||',
          'refs/remotes/origin/feature|ghi789012345678901234567890abcdef123456||||'
        ].join("\n")
      end

      it 'returns parsed branch data as array of BranchInfo objects' do
        allow_command(*expected_args, stdout: format_output)
        result = command.call
        expect(result).to be_an(Array)
        expect(result.size).to eq(4)
        expect(result).to all(be_a(Git::BranchInfo))
      end

      it 'parses target_oid from objectname' do
        allow_command(*expected_args, stdout: format_output)
        result = command.call
        expect(result[0].target_oid).to eq('abc123def456789012345678901234567890abcd')
        expect(result[1].target_oid).to eq('def456789012345678901234567890abcdef12')
      end

      it 'marks current branch correctly from HEAD field' do
        allow_command(*expected_args, stdout: format_output)
        result = command.call
        expect(result[0]).to have_attributes(refname: 'main', current: true)
        expect(result[1]).to have_attributes(refname: 'feature-branch', current: false)
      end

      it 'parses upstream as BranchInfo' do
        allow_command(*expected_args, stdout: format_output)
        result = command.call
        main_branch = result[0]

        expect(main_branch.upstream).to be_a(Git::BranchInfo)
        expect(main_branch.upstream.refname).to eq('remotes/origin/main')
        expect(main_branch.upstream.upstream).to be_nil
      end

      it 'sets upstream to nil when not configured' do
        allow_command(*expected_args, stdout: format_output)
        result = command.call
        expect(result[1].upstream).to be_nil  # feature-branch has no upstream
        expect(result[2].upstream).to be_nil  # remote-tracking branches don't have upstreams
      end

      it 'parses remote branch names' do
        allow_command(*expected_args, stdout: format_output)
        result = command.call
        expect(result[2].refname).to eq('remotes/origin/main')
        expect(result[3].refname).to eq('remotes/origin/feature')
      end
    end

    context 'with worktree branch' do
      let(:worktree_output) do
        [
          'refs/heads/main|abc123def456789012345678901234567890abcd|*|||',
          'refs/heads/feature-in-worktree|def456789012345678901234567890abcdef12||/path/to/worktree||',
          'refs/heads/other-branch|ghi789012345678901234567890abcdef123456||||'
        ].join("\n")
      end

      it 'marks worktree branch correctly from worktreepath field' do
        allow_command(*expected_args, stdout: worktree_output)
        result = command.call
        expect(result[0]).to have_attributes(refname: 'main', current: true, worktree: false)
        expect(result[1]).to have_attributes(refname: 'feature-in-worktree', current: false, worktree: true)
        expect(result[2]).to have_attributes(refname: 'other-branch', current: false, worktree: false)
      end
    end

    context 'with symbolic reference' do
      let(:symref_output) do
        [
          'refs/heads/HEAD|abc123def456789012345678901234567890abcd|||refs/heads/main|',
          'refs/heads/main|abc123def456789012345678901234567890abcd|*|||'
        ].join("\n")
      end

      it 'includes symbolic reference information' do
        allow_command(*expected_args, stdout: symref_output)
        result = command.call
        expect(result[0].symref).to eq('refs/heads/main')
        expect(result[1].symref).to be_nil
      end
    end

    context 'with unsupported options' do
      it 'raises ArgumentError' do
        expect { command.call(invalid_option: true) }.to raise_error(ArgumentError, /unsupported/i)
      end
    end

    context 'with empty fields in output' do
      let(:empty_fields_output) do
        'refs/heads/main|abc123def456789012345678901234567890abcd||||'
      end

      it 'handles empty fields gracefully' do
        allow_command(*expected_args, stdout: empty_fields_output)
        result = command.call
        expect(result[0]).to have_attributes(
          refname: 'main',
          target_oid: 'abc123def456789012345678901234567890abcd',
          current: false,
          worktree: false,
          symref: nil,
          upstream: nil
        )
      end
    end

    context 'with detached HEAD in output' do
      let(:detached_head_output) do
        [
          '(HEAD detached at v1.0.0)|abc123def456789012345678901234567890abcd|*|||',
          'refs/heads/master|def456789012345678901234567890abcdef12||||',
          'refs/remotes/origin/master|ghi789012345678901234567890abcdef123456||||'
        ].join("\n")
      end

      it 'filters out detached HEAD entries' do
        allow_command(*expected_args, stdout: detached_head_output)
        result = command.call

        expect(result.size).to eq(2)
        expect(result.map(&:refname)).to contain_exactly('master', 'remotes/origin/master')
        expect(result.none? { |b| b.refname.include?('detached') }).to be true
      end
    end

    context 'with (not a branch) in output' do
      let(:not_a_branch_output) do
        [
          '(not a branch)|abc123def456789012345678901234567890abcd|*|||',
          'refs/heads/master|def456789012345678901234567890abcdef12||||'
        ].join("\n")
      end

      it 'filters out (not a branch) entries' do
        allow_command(*expected_args, stdout: not_a_branch_output)
        result = command.call

        expect(result.size).to eq(1)
        expect(result.first.refname).to eq('master')
        expect(result.none? { |b| b.refname.include?('not a branch') }).to be true
      end
    end
  end
end
