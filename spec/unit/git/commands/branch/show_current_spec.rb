# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/show_current'
require 'git/detached_head_info'

RSpec.describe Git::Commands::Branch::ShowCurrent do
  subject(:command) { described_class.new(execution_context) }

  let(:execution_context) { instance_double(Git::Lib) }
  let(:command_result) { instance_double(Git::CommandLineResult, stdout: stdout, stderr: '', status: success_status) }
  let(:success_status) { instance_double(Process::Status, success?: true) }

  describe '#call' do
    context 'when on a branch' do
      let(:stdout) { "main\n" }
      let(:branch_info) do
        Git::BranchInfo.new(
          refname: 'main',
          target_oid: 'abc123def456',
          current: true,
          worktree: false,
          symref: nil,
          upstream: nil
        )
      end

      before do
        allow(execution_context).to receive(:command)
          .with('branch', '--show-current')
          .and_return(command_result)

        list_command = instance_double(Git::Commands::Branch::List)
        allow(Git::Commands::Branch::List).to receive(:new)
          .with(execution_context)
          .and_return(list_command)
        allow(list_command).to receive(:call)
          .with('main')
          .and_return([branch_info])
      end

      it 'executes git branch --show-current' do
        command.call
        expect(execution_context).to have_received(:command).with('branch', '--show-current')
      end

      it 'returns the BranchInfo for the current branch' do
        result = command.call
        expect(result).to eq(branch_info)
      end

      it 'looks up the branch info via List command' do
        command.call
        expect(Git::Commands::Branch::List).to have_received(:new).with(execution_context)
      end
    end

    context 'when on a feature branch with slashes' do
      let(:stdout) { "feature/my-feature\n" }
      let(:branch_info) do
        Git::BranchInfo.new(
          refname: 'feature/my-feature',
          target_oid: 'def456abc789',
          current: true,
          worktree: false,
          symref: nil,
          upstream: nil
        )
      end

      before do
        allow(execution_context).to receive(:command)
          .with('branch', '--show-current')
          .and_return(command_result)

        list_command = instance_double(Git::Commands::Branch::List)
        allow(Git::Commands::Branch::List).to receive(:new)
          .with(execution_context)
          .and_return(list_command)
        allow(list_command).to receive(:call)
          .with('feature/my-feature')
          .and_return([branch_info])
      end

      it 'returns the BranchInfo for the feature branch' do
        result = command.call
        expect(result).to eq(branch_info)
        expect(result.short_name).to eq('feature/my-feature')
      end
    end

    context 'when on an unborn branch' do
      let(:stdout) { "new-branch\n" }

      before do
        allow(execution_context).to receive(:command)
          .with('branch', '--show-current')
          .and_return(command_result)

        list_command = instance_double(Git::Commands::Branch::List)
        allow(Git::Commands::Branch::List).to receive(:new)
          .with(execution_context)
          .and_return(list_command)
        allow(list_command).to receive(:call)
          .with('new-branch')
          .and_return([])
      end

      it 'returns a minimal BranchInfo with nil target_oid' do
        result = command.call

        expect(result).to be_a(Git::BranchInfo)
        expect(result.short_name).to eq('new-branch')
        expect(result.target_oid).to be_nil
        expect(result.current?).to be true
      end
    end

    context 'when in detached HEAD state' do
      let(:stdout) { '' }
      let(:rev_parse_result) { instance_double(Git::CommandLineResult, stdout: "abc123def456789\n", stderr: '', status: success_status) }

      before do
        allow(execution_context).to receive(:command)
          .with('branch', '--show-current')
          .and_return(command_result)
        allow(execution_context).to receive(:command)
          .with('rev-parse', 'HEAD')
          .and_return(rev_parse_result)
      end

      it 'returns a DetachedHeadInfo' do
        result = command.call
        expect(result).to be_a(Git::DetachedHeadInfo)
      end

      it 'includes the commit SHA' do
        result = command.call
        expect(result.target_oid).to eq('abc123def456789')
      end

      it 'reports as detached' do
        result = command.call
        expect(result.detached?).to be true
      end

      it 'has short_name of HEAD' do
        result = command.call
        expect(result.short_name).to eq('HEAD')
      end

      it 'does not look up branch info' do
        expect(Git::Commands::Branch::List).not_to receive(:new)
        command.call
      end
    end

    context 'when stdout has only whitespace' do
      let(:stdout) { "   \n" }
      let(:rev_parse_result) { instance_double(Git::CommandLineResult, stdout: "def789abc123456\n", stderr: '', status: success_status) }

      before do
        allow(execution_context).to receive(:command)
          .with('branch', '--show-current')
          .and_return(command_result)
        allow(execution_context).to receive(:command)
          .with('rev-parse', 'HEAD')
          .and_return(rev_parse_result)
      end

      it 'returns DetachedHeadInfo (treats as detached HEAD)' do
        result = command.call
        expect(result).to be_a(Git::DetachedHeadInfo)
        expect(result.target_oid).to eq('def789abc123456')
      end
    end
  end
end
