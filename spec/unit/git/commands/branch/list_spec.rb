# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/list'
require 'git/parsers/branch'

RSpec.describe Git::Commands::Branch::List do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # Format string used by the command (defined in BranchParser)
  let(:format_string) { Git::Parsers::Branch::FORMAT_STRING }

  let(:sample_output) { "refs/heads/main|abc123|*|||\n" }

  # Helper to build expected command arguments
  def expected_args(*extra_args)
    ['branch', '--list', "--format=#{format_string}", *extra_args]
  end

  describe '#call' do
    context 'with no options (basic list)' do
      it 'runs branch with --list and format flags' do
        expect(execution_context).to receive(:command)
          .with(*expected_args)
          .and_return(command_result(sample_output))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq(sample_output)
      end
    end

    context 'with :all option' do
      it 'adds --all flag' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--all'))
          .and_return(command_result(''))

        result = command.call(all: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'accepts :a alias' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--all'))
          .and_return(command_result(''))

        result = command.call(a: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :remotes option' do
      it 'adds --remotes flag' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--remotes'))
          .and_return(command_result(''))

        result = command.call(remotes: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'accepts :r alias' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--remotes'))
          .and_return(command_result(''))

        result = command.call(r: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :sort option' do
      it 'adds --sort=<key> with single value' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--sort=refname'))
          .and_return(command_result(''))

        result = command.call(sort: 'refname')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'adds multiple --sort=<key> with array of values' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--sort=refname', '--sort=-committerdate'))
          .and_return(command_result(''))

        result = command.call(sort: ['refname', '-committerdate'])

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :ignore_case option' do
      it 'adds --ignore-case flag' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--ignore-case'))
          .and_return(command_result(''))

        result = command.call(ignore_case: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'accepts :i alias' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--ignore-case'))
          .and_return(command_result(''))

        result = command.call(i: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :contains option' do
      it 'adds --contains <commit> with string value' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--contains', 'abc123'))
          .and_return(command_result(''))

        result = command.call(contains: 'abc123')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'adds --contains flag with true (defaults to HEAD)' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--contains'))
          .and_return(command_result(''))

        result = command.call(contains: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :no_contains option' do
      it 'adds --no-contains <commit> with string value' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--no-contains', 'abc123'))
          .and_return(command_result(''))

        result = command.call(no_contains: 'abc123')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'adds --no-contains flag with true (defaults to HEAD)' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--no-contains'))
          .and_return(command_result(''))

        result = command.call(no_contains: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :merged option' do
      it 'adds --merged <commit> with string value' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--merged', 'main'))
          .and_return(command_result(''))

        result = command.call(merged: 'main')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'adds --merged flag with true (defaults to HEAD)' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--merged'))
          .and_return(command_result(''))

        result = command.call(merged: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :no_merged option' do
      it 'adds --no-merged <commit> with string value' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--no-merged', 'main'))
          .and_return(command_result(''))

        result = command.call(no_merged: 'main')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'adds --no-merged flag with true (defaults to HEAD)' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--no-merged'))
          .and_return(command_result(''))

        result = command.call(no_merged: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :points_at option' do
      it 'adds --points-at <object>' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--points-at', 'v1.0'))
          .and_return(command_result(''))

        result = command.call(points_at: 'v1.0')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with patterns' do
      it 'adds pattern arguments' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('feature/*'))
          .and_return(command_result(''))

        result = command.call('feature/*')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'adds multiple pattern arguments' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('feature/*', 'bugfix/*'))
          .and_return(command_result(''))

        result = command.call('feature/*', 'bugfix/*')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with multiple options' do
      it 'combines flags correctly' do
        expect(execution_context).to receive(:command)
          .with(*expected_args('--all', '--sort=refname', '--contains', 'abc123'))
          .and_return(command_result(''))

        result = command.call(all: true, sort: 'refname', contains: 'abc123')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(invalid_option: true) }.to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
