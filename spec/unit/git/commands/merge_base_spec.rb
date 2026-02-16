# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/merge_base'

RSpec.describe Git::Commands::MergeBase do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with two commits' do
      it 'runs merge-base with both commits' do
        expected_result = command_result("abc123\n")
        expect(execution_context).to receive(:command)
          .with('merge-base', 'main', 'feature')
          .and_return(expected_result)

        result = command.call('main', 'feature')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple commits' do
      it 'passes all commits as operands' do
        expect(execution_context).to receive(:command)
          .with('merge-base', 'main', 'feature1', 'feature2')
          .and_return(command_result("abc123\n"))

        command.call('main', 'feature1', 'feature2')
      end
    end

    context 'with :octopus option' do
      it 'includes the --octopus flag' do
        expect(execution_context).to receive(:command)
          .with('merge-base', '--octopus', 'main', 'b1', 'b2')
          .and_return(command_result("abc123\n"))

        command.call('main', 'b1', 'b2', octopus: true)
      end
    end

    context 'with :independent option' do
      it 'includes the --independent flag' do
        expect(execution_context).to receive(:command)
          .with('merge-base', '--independent', 'a', 'b', 'c')
          .and_return(command_result("sha1\nsha2\n"))

        command.call('a', 'b', 'c', independent: true)
      end
    end

    context 'with :fork_point option' do
      it 'includes the --fork-point flag' do
        expect(execution_context).to receive(:command)
          .with('merge-base', '--fork-point', 'main', 'feature')
          .and_return(command_result("abc123\n"))

        command.call('main', 'feature', fork_point: true)
      end
    end

    context 'with :all option' do
      it 'includes the --all flag' do
        expect(execution_context).to receive(:command)
          .with('merge-base', '--all', 'main', 'feature')
          .and_return(command_result("sha1\nsha2\n"))

        command.call('main', 'feature', all: true)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in correct order' do
        expect(execution_context).to receive(:command)
          .with('merge-base', '--octopus', '--all', 'main', 'b1', 'b2')
          .and_return(command_result("sha1\nsha2\n"))

        command.call('main', 'b1', 'b2', octopus: true, all: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when no commits provided' do
        expect { command.call }.to raise_error(ArgumentError)
      end
    end
  end
end
