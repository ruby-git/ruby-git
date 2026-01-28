# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/create'
require 'git/commands/branch/list'

RSpec.describe Git::Commands::Branch::Create do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # Create a BranchInfo for testing
  def build_branch_info(branch_name)
    Git::BranchInfo.new(refname: branch_name, current: false, worktree: false, symref: nil)
  end

  # Set up mock for Branch::List command
  def stub_list_command(branch_name, expected_branch_info)
    list_command = instance_double(Git::Commands::Branch::List)
    allow(Git::Commands::Branch::List).to receive(:new).with(execution_context).and_return(list_command)
    allow(list_command).to receive(:call).with(branch_name).and_return([expected_branch_info])
  end

  # Helper to set up expectations for both the create command and the subsequent list lookup
  def expect_create_and_list(expected_args, branch_name: 'feature-branch')
    expected_branch_info = build_branch_info(branch_name)
    stub_list_command(branch_name, expected_branch_info)
    expect(execution_context).to receive(:command).with(*expected_args)
    expected_branch_info
  end

  describe '#call' do
    context 'with branch name only (basic creation)' do
      it 'calls git branch with the branch name and returns BranchInfo' do
        expected_branch_info = expect_create_and_list(%w[branch feature-branch])
        result = command.call('feature-branch')
        expect(result).to eq(expected_branch_info)
      end
    end

    context 'with start_point' do
      it 'adds the start point after the branch name' do
        expected_branch_info = expect_create_and_list(%w[branch feature-branch main])
        result = command.call('feature-branch', 'main')
        expect(result).to eq(expected_branch_info)
      end

      it 'accepts a commit SHA as start point' do
        expected_branch_info = expect_create_and_list(%w[branch feature-branch abc123])
        result = command.call('feature-branch', 'abc123')
        expect(result).to eq(expected_branch_info)
      end

      it 'accepts a tag as start point' do
        expected_branch_info = expect_create_and_list(['branch', 'feature-branch', 'v1.0.0'])
        result = command.call('feature-branch', 'v1.0.0')
        expect(result).to eq(expected_branch_info)
      end

      it 'accepts a remote branch as start point' do
        expected_branch_info = expect_create_and_list(['branch', 'feature-branch', 'origin/main'])
        result = command.call('feature-branch', 'origin/main')
        expect(result).to eq(expected_branch_info)
      end
    end

    context 'with :force option' do
      it 'adds --force flag' do
        expected_branch_info = expect_create_and_list(['branch', '--force', 'feature-branch'])
        result = command.call('feature-branch', force: true)
        expect(result).to eq(expected_branch_info)
      end

      it 'allows resetting an existing branch to a new start point' do
        expected_branch_info = expect_create_and_list(['branch', '--force', 'feature-branch', 'main'])
        result = command.call('feature-branch', 'main', force: true)
        expect(result).to eq(expected_branch_info)
      end

      it 'does not add flag when false' do
        expected_branch_info = expect_create_and_list(%w[branch feature-branch])
        result = command.call('feature-branch', force: false)
        expect(result).to eq(expected_branch_info)
      end
    end

    context 'with :create_reflog option' do
      it 'adds --create-reflog flag' do
        expected_branch_info = expect_create_and_list(['branch', '--create-reflog', 'feature-branch'])
        result = command.call('feature-branch', create_reflog: true)
        expect(result).to eq(expected_branch_info)
      end

      it 'does not add flag when false' do
        expected_branch_info = expect_create_and_list(%w[branch feature-branch])
        result = command.call('feature-branch', create_reflog: false)
        expect(result).to eq(expected_branch_info)
      end
    end

    context 'with :recurse_submodules option' do
      it 'adds --recurse-submodules flag' do
        expected_branch_info = expect_create_and_list(['branch', '--recurse-submodules', 'feature-branch'])
        result = command.call('feature-branch', recurse_submodules: true)
        expect(result).to eq(expected_branch_info)
      end

      it 'does not add flag when false' do
        expected_branch_info = expect_create_and_list(%w[branch feature-branch])
        result = command.call('feature-branch', recurse_submodules: false)
        expect(result).to eq(expected_branch_info)
      end
    end

    context 'with :track option' do
      context 'when true' do
        it 'adds --track flag' do
          expected_branch_info = expect_create_and_list(['branch', '--track', 'feature-branch', 'origin/main'])
          result = command.call('feature-branch', 'origin/main', track: true)
          expect(result).to eq(expected_branch_info)
        end
      end

      context 'when false' do
        it 'adds --no-track flag' do
          expected_branch_info = expect_create_and_list(['branch', '--no-track', 'feature-branch', 'origin/main'])
          result = command.call('feature-branch', 'origin/main', track: false)
          expect(result).to eq(expected_branch_info)
        end
      end

      context 'when "direct"' do
        it 'adds --track=direct flag' do
          expected_branch_info = expect_create_and_list(
            ['branch', '--track=direct', 'feature-branch', 'origin/main']
          )
          result = command.call('feature-branch', 'origin/main', track: 'direct')
          expect(result).to eq(expected_branch_info)
        end
      end

      context 'when "inherit"' do
        it 'adds --track=inherit flag' do
          expected_branch_info = expect_create_and_list(
            ['branch', '--track=inherit', 'feature-branch', 'origin/main']
          )
          result = command.call('feature-branch', 'origin/main', track: 'inherit')
          expect(result).to eq(expected_branch_info)
        end
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in correct order' do
        expected_branch_info = expect_create_and_list(
          ['branch', '--force', '--create-reflog', '--track', 'feature-branch', 'origin/main']
        )
        result = command.call('feature-branch', 'origin/main', force: true, create_reflog: true, track: true)
        expect(result).to eq(expected_branch_info)
      end

      it 'combines force with no-track' do
        expected_branch_info = expect_create_and_list(
          ['branch', '--force', '--no-track', 'feature-branch', 'main']
        )
        result = command.call('feature-branch', 'main', force: true, track: false)
        expect(result).to eq(expected_branch_info)
      end
    end

    context 'with nil start_point' do
      it 'omits the start point from the command' do
        expected_branch_info = expect_create_and_list(%w[branch feature-branch])
        result = command.call('feature-branch', nil)
        expect(result).to eq(expected_branch_info)
      end

      it 'omits the start point when options are provided' do
        expected_branch_info = expect_create_and_list(['branch', '--force', 'feature-branch'])
        result = command.call('feature-branch', nil, force: true)
        expect(result).to eq(expected_branch_info)
      end
    end
  end
end
