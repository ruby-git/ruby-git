# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/list'

RSpec.describe Git::Commands::Branch::List do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  # Helper to build expected command arguments
  def expected_args(*extra_args)
    ['branch', '--list', *extra_args]
  end

  describe '#call' do
    context 'with no options' do
      it 'runs git branch --list and returns the result' do
        expected_result = command_result("main\n")
        expect_command_capturing(*expected_args).and_return(expected_result)
        result = command.call
        expect(result).to eq(expected_result)
      end
    end

    context 'with :color option' do
      it 'adds --color with true' do
        expect_command_capturing(*expected_args('--color')).and_return(command_result(''))
        command.call(color: true)
      end

      it 'adds --color=<when> with string value' do
        expect_command_capturing(*expected_args('--color=always')).and_return(command_result(''))
        command.call(color: 'always')
      end

      context 'when :no_color is true' do
        it 'adds --no-color' do
          expect_command_capturing(*expected_args('--no-color')).and_return(command_result(''))
          command.call(no_color: true)
        end
      end
    end

    context 'with :verbose option' do
      it 'adds --verbose with true' do
        expect_command_capturing(*expected_args('--verbose')).and_return(command_result(''))
        command.call(verbose: true)
      end

      it 'adds --verbose --verbose with 2' do
        expect_command_capturing(*expected_args('--verbose', '--verbose')).and_return(command_result(''))
        command.call(verbose: 2)
      end

      it 'accepts :v alias' do
        expect_command_capturing(*expected_args('--verbose')).and_return(command_result(''))
        command.call(v: true)
      end
    end

    context 'with :abbrev option' do
      it 'adds --abbrev=<n> with integer value' do
        expect_command_capturing(*expected_args('--abbrev=7')).and_return(command_result(''))
        command.call(abbrev: 7)
      end

      it 'adds --abbrev with true' do
        expect_command_capturing(*expected_args('--abbrev')).and_return(command_result(''))
        command.call(abbrev: true)
      end

      context 'when :no_abbrev is true' do
        it 'adds --no-abbrev' do
          expect_command_capturing(*expected_args('--no-abbrev')).and_return(command_result(''))
          command.call(no_abbrev: true)
        end
      end
    end

    context 'with :column option' do
      it 'adds --column with true' do
        expect_command_capturing(*expected_args('--column')).and_return(command_result(''))
        command.call(column: true)
      end

      it 'adds --column=<options> with string value' do
        expect_command_capturing(*expected_args('--column=dense')).and_return(command_result(''))
        command.call(column: 'dense')
      end

      context 'when :no_column is true' do
        it 'adds --no-column' do
          expect_command_capturing(*expected_args('--no-column')).and_return(command_result(''))
          command.call(no_column: true)
        end
      end
    end

    context 'with :sort option' do
      it 'adds --sort=<key> with single value' do
        expect_command_capturing(*expected_args('--sort=refname')).and_return(command_result(''))
        command.call(sort: 'refname')
      end

      it 'adds multiple --sort=<key> with array of values' do
        expect_command_capturing(*expected_args('--sort=refname', '--sort=-committerdate'))
          .and_return(command_result(''))
        command.call(sort: ['refname', '-committerdate'])
      end
    end

    context 'with :merged option' do
      it 'adds --merged <commit> with string value' do
        expect_command_capturing(*expected_args('--merged', 'main')).and_return(command_result(''))
        command.call(merged: 'main')
      end

      it 'adds --merged with true' do
        expect_command_capturing(*expected_args('--merged')).and_return(command_result(''))
        command.call(merged: true)
      end
    end

    context 'with :no_merged option' do
      it 'adds --no-merged <commit> with string value' do
        expect_command_capturing(*expected_args('--no-merged', 'main')).and_return(command_result(''))
        command.call(no_merged: 'main')
      end

      it 'adds --no-merged with true' do
        expect_command_capturing(*expected_args('--no-merged')).and_return(command_result(''))
        command.call(no_merged: true)
      end
    end

    context 'with :contains option' do
      it 'adds --contains <commit> with string value' do
        expect_command_capturing(*expected_args('--contains', 'abc123')).and_return(command_result(''))
        command.call(contains: 'abc123')
      end

      it 'adds --contains with true' do
        expect_command_capturing(*expected_args('--contains')).and_return(command_result(''))
        command.call(contains: true)
      end
    end

    context 'with :no_contains option' do
      it 'adds --no-contains <commit> with string value' do
        expect_command_capturing(*expected_args('--no-contains', 'abc123')).and_return(command_result(''))
        command.call(no_contains: 'abc123')
      end

      it 'adds --no-contains with true' do
        expect_command_capturing(*expected_args('--no-contains')).and_return(command_result(''))
        command.call(no_contains: true)
      end
    end

    context 'with :points_at option' do
      it 'adds --points-at <object>' do
        expect_command_capturing(*expected_args('--points-at', 'v1.0')).and_return(command_result(''))
        command.call(points_at: 'v1.0')
      end
    end

    context 'with :format option' do
      it 'includes --format=<string>' do
        expect_command_capturing(*expected_args('--format=%(refname)')).and_return(command_result(''))
        command.call(format: '%(refname)')
      end
    end

    context 'with :remotes option' do
      it 'adds --remotes' do
        expect_command_capturing(*expected_args('--remotes')).and_return(command_result(''))
        command.call(remotes: true)
      end

      it 'accepts :r alias' do
        expect_command_capturing(*expected_args('--remotes')).and_return(command_result(''))
        command.call(r: true)
      end
    end

    context 'with :all option' do
      it 'adds --all' do
        expect_command_capturing(*expected_args('--all')).and_return(command_result(''))
        command.call(all: true)
      end

      it 'accepts :a alias' do
        expect_command_capturing(*expected_args('--all')).and_return(command_result(''))
        command.call(a: true)
      end
    end

    context 'with :ignore_case option' do
      it 'adds --ignore-case' do
        expect_command_capturing(*expected_args('--ignore-case')).and_return(command_result(''))
        command.call(ignore_case: true)
      end

      it 'accepts :i alias' do
        expect_command_capturing(*expected_args('--ignore-case')).and_return(command_result(''))
        command.call(i: true)
      end
    end

    context 'with :omit_empty option' do
      it 'adds --omit-empty' do
        expect_command_capturing(*expected_args('--omit-empty')).and_return(command_result(''))
        command.call(omit_empty: true)
      end
    end

    context 'with patterns' do
      it 'adds a single pattern after end-of-options marker' do
        expect_command_capturing(*expected_args('--', 'feature/*')).and_return(command_result(''))
        command.call('feature/*')
      end

      it 'adds multiple patterns after end-of-options marker' do
        expect_command_capturing(*expected_args('--', 'feature/*', 'bugfix/*')).and_return(command_result(''))
        command.call('feature/*', 'bugfix/*')
      end
    end

    context 'with options and patterns combined' do
      it 'places options before end-of-options marker and patterns after' do
        expect_command_capturing(*expected_args('--all', '--', 'feature/*')).and_return(command_result(''))
        command.call('feature/*', all: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(invalid_option: true) }.to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
