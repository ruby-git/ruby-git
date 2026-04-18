# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/merge_base'

RSpec.describe Git::Commands::MergeBase do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with two commits' do
      it 'runs merge-base with both commits' do
        expected_result = command_result("abc123\n")
        expect_command_capturing('merge-base', '--', 'main', 'feature').and_return(expected_result)

        result = command.call('main', 'feature')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple commits' do
      it 'passes all commits as operands' do
        expect_command_capturing('merge-base', '--', 'main', 'feature1',
                                 'feature2').and_return(command_result("abc123\n"))

        command.call('main', 'feature1', 'feature2')
      end
    end

    context 'with :octopus option' do
      it 'includes the --octopus flag' do
        expect_command_capturing('merge-base', '--octopus', '--', 'main', 'b1',
                                 'b2').and_return(command_result("abc123\n"))

        command.call('main', 'b1', 'b2', octopus: true)
      end
    end

    context 'with :independent option' do
      it 'includes the --independent flag' do
        expect_command_capturing('merge-base', '--independent', '--', 'a', 'b',
                                 'c').and_return(command_result("sha1\nsha2\n"))

        command.call('a', 'b', 'c', independent: true)
      end
    end

    context 'with :is_ancestor option' do
      it 'includes the --is-ancestor flag' do
        expect_command_capturing('merge-base', '--is-ancestor', '--', 'main',
                                 'feature').and_return(command_result(''))

        command.call('main', 'feature', is_ancestor: true)
      end
    end

    context 'with :fork_point option' do
      it 'includes the --fork-point flag' do
        expect_command_capturing('merge-base', '--fork-point', '--', 'main',
                                 'feature').and_return(command_result("abc123\n"))

        command.call('main', 'feature', fork_point: true)
      end
    end

    context 'with :all option' do
      it 'includes the --all flag' do
        expect_command_capturing('merge-base', '--all', '--', 'main',
                                 'feature').and_return(command_result("sha1\nsha2\n"))

        command.call('main', 'feature', all: true)
      end
    end

    context 'with :a alias for :all' do
      it 'includes the --all flag' do
        expect_command_capturing('merge-base', '--all', '--', 'main',
                                 'feature').and_return(command_result("sha1\nsha2\n"))

        command.call('main', 'feature', a: true)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in correct order' do
        expect_command_capturing('merge-base', '--octopus', '--all', '--', 'main', 'b1',
                                 'b2').and_return(command_result("sha1\nsha2\n"))

        command.call('main', 'b1', 'b2', octopus: true, all: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when no commits provided' do
        expect { command.call }.to raise_error(ArgumentError)
      end
    end

    context 'exit code handling' do
      it 'returns the result without raising when exit status is 1' do
        exit1_result = command_result('', exitstatus: 1)
        expect_command_capturing('merge-base', '--fork-point', '--', 'main', 'feature')
          .and_return(exit1_result)

        result = command.call('main', 'feature', fork_point: true)

        expect(result.status.exitstatus).to eq(1)
      end

      it 'raises Git::FailedError when exit status is 2' do
        expect_command_capturing('merge-base', '--', 'main', 'feature')
          .and_return(command_result('', stderr: 'fatal: bad revision', exitstatus: 2))

        expect { command.call('main', 'feature') }.to raise_error(Git::FailedError)
      end

      it 'raises Git::FailedError when exit status is 128' do
        expect_command_capturing('merge-base', '--', 'main', 'feature')
          .and_return(command_result('', stderr: 'fatal: not a git repository', exitstatus: 128))

        expect { command.call('main', 'feature') }.to raise_error(Git::FailedError)
      end
    end
  end
end
