# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/list'

RSpec.describe Git::Commands::Branch::List do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no options (basic list)' do
      it 'calls git branch --list with no additional arguments' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list').and_return([])
        command.call
      end
    end

    context 'with :all option' do
      it 'adds -a flag' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list', '-a').and_return([])
        command.call(all: true)
      end
    end

    context 'with :remotes option' do
      it 'adds -r flag' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list', '-r').and_return([])
        command.call(remotes: true)
      end
    end

    context 'with :sort option' do
      it 'adds --sort=<key> with single value' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list', '--sort=refname').and_return([])
        command.call(sort: 'refname')
      end

      it 'adds multiple --sort=<key> with array of values' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list', '--sort=refname',
                                                                  '--sort=-committerdate').and_return([])
        command.call(sort: ['refname', '-committerdate'])
      end
    end

    context 'with :contains option' do
      it 'adds --contains <commit>' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list', '--contains',
                                                                  'abc123').and_return([])
        command.call(contains: 'abc123')
      end
    end

    context 'with :no_contains option' do
      it 'adds --no-contains <commit>' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list', '--no-contains',
                                                                  'abc123').and_return([])
        command.call(no_contains: 'abc123')
      end
    end

    context 'with :merged option' do
      it 'adds --merged <commit>' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list', '--merged', 'main').and_return([])
        command.call(merged: 'main')
      end
    end

    context 'with :no_merged option' do
      it 'adds --no-merged <commit>' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list', '--no-merged',
                                                                  'main').and_return([])
        command.call(no_merged: 'main')
      end
    end

    context 'with :points_at option' do
      it 'adds --points-at <object>' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list', '--points-at',
                                                                  'v1.0').and_return([])
        command.call(points_at: 'v1.0')
      end
    end

    context 'with patterns' do
      it 'adds pattern arguments' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list', 'feature/*').and_return([])
        command.call('feature/*')
      end

      it 'adds multiple pattern arguments' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list', 'feature/*',
                                                                  'bugfix/*').and_return([])
        command.call('feature/*', 'bugfix/*')
      end
    end

    context 'with multiple options' do
      it 'combines flags correctly' do
        expect(execution_context).to receive(:command_lines).with(
          'branch', '--list', '-a', '--sort=refname', '--contains', 'abc123'
        ).and_return([])
        command.call(all: true, sort: 'refname', contains: 'abc123')
      end
    end

    context 'when parsing branch output' do
      let(:branch_output) do
        [
          '* main',
          '  feature-branch',
          '  remotes/origin/main',
          '  remotes/origin/feature-branch'
        ]
      end

      it 'returns parsed branch data as array of BranchInfo objects' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list').and_return(branch_output)
        result = command.call
        expect(result).to be_an(Array)
        expect(result.size).to eq(4)
        expect(result).to all(be_a(Git::BranchInfo))
      end

      it 'marks current branch correctly' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list').and_return(branch_output)
        result = command.call
        expect(result[0]).to have_attributes(refname: 'main', current: true, worktree: false, symref: nil)
        expect(result[1]).to have_attributes(refname: 'feature-branch', current: false, worktree: false, symref: nil)
      end

      it 'parses remote branch names' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list').and_return(branch_output)
        result = command.call
        expect(result[2].refname).to eq('remotes/origin/main')
        expect(result[3].refname).to eq('remotes/origin/feature-branch')
      end
    end

    context 'with worktree branch' do
      let(:worktree_output) do
        [
          '* main',
          '+ feature-in-worktree',
          '  other-branch'
        ]
      end

      it 'marks worktree branch correctly' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list').and_return(worktree_output)
        result = command.call
        expect(result[0]).to have_attributes(refname: 'main', current: true, worktree: false, symref: nil)
        expect(result[1]).to have_attributes(
          refname: 'feature-in-worktree', current: false, worktree: true, symref: nil
        )
        expect(result[2]).to have_attributes(refname: 'other-branch', current: false, worktree: false, symref: nil)
      end
    end

    context 'with detached HEAD state' do
      let(:detached_output) do
        [
          '* (HEAD detached at v1.0)',
          '  main',
          '  feature-branch'
        ]
      end

      it 'filters out detached HEAD lines' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list').and_return(detached_output)
        result = command.call
        expect(result.size).to eq(2)
        expect(result.map(&:refname)).to eq(%w[main feature-branch])
      end
    end

    context 'with (not a branch) line' do
      let(:not_a_branch_output) do
        [
          '* (not a branch)',
          '  main',
          '  feature-branch'
        ]
      end

      it 'filters out (not a branch) lines' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list').and_return(not_a_branch_output)
        result = command.call
        expect(result.size).to eq(2)
        expect(result.map(&:refname)).to eq(%w[main feature-branch])
      end
    end

    context 'with symbolic reference' do
      let(:symref_output) do
        [
          '  main -> origin/main',
          '  feature-branch'
        ]
      end

      it 'includes symbolic reference information' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list').and_return(symref_output)
        result = command.call
        expect(result[0].symref).to eq('origin/main')
      end
    end

    context 'with unsupported options' do
      it 'raises ArgumentError' do
        expect { command.call(invalid_option: true) }.to raise_error(ArgumentError, /unsupported/i)
      end
    end

    context 'with unexpected git output format' do
      let(:malformed_output) do
        [
          'malformed line without proper prefix',
          '  valid-branch'
        ]
      end

      it 'raises Git::UnexpectedResultError' do
        expect(execution_context).to receive(:command_lines).with('branch', '--list').and_return(malformed_output)
        expect { command.call }.to raise_error(Git::UnexpectedResultError)
      end
    end
  end
end
