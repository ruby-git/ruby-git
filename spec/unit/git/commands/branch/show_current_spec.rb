# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/show_current'

RSpec.describe Git::Commands::Branch::ShowCurrent do
  subject(:command) { described_class.new(execution_context) }

  let(:execution_context) { instance_double(Git::Lib) }

  describe '#call' do
    context 'when on a branch' do
      it 'runs branch --show-current' do
        expect(execution_context).to receive(:command)
          .with('branch', '--show-current')
          .and_return(command_result("main\n"))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq("main\n")
      end
    end

    context 'when in detached HEAD state' do
      it 'returns empty stdout' do
        expect(execution_context).to receive(:command)
          .with('branch', '--show-current')
          .and_return(command_result(''))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq('')
      end
    end

    context 'when on a feature branch with slashes' do
      it 'returns the full branch name in stdout' do
        expect(execution_context).to receive(:command)
          .with('branch', '--show-current')
          .and_return(command_result("feature/my-feature\n"))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq("feature/my-feature\n")
      end
    end
  end
end
