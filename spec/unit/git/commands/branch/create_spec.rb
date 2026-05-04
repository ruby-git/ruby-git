# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/create'

RSpec.describe Git::Commands::Branch::Create do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with branch name only (basic creation)' do
      it 'runs branch with the branch name' do
        expected_result = command_result('')
        expect_command_capturing('branch', '--', 'feature-branch')
          .and_return(expected_result)

        result = command.call('feature-branch')

        expect(result).to eq(expected_result)
      end
    end

    context 'with start_point' do
      it 'adds the start point after the branch name' do
        expect_command_capturing('branch', '--', 'feature-branch', 'main')
          .and_return(command_result(''))

        command.call('feature-branch', 'main')
      end
    end

    context 'with :force option' do
      it 'adds --force flag' do
        expect_command_capturing('branch', '--force', '--', 'feature-branch')
          .and_return(command_result(''))

        command.call('feature-branch', force: true)
      end

      it 'allows resetting an existing branch to a new start point' do
        expect_command_capturing('branch', '--force', '--', 'feature-branch', 'main')
          .and_return(command_result(''))

        command.call('feature-branch', 'main', force: true)
      end
    end

    context 'with :f short option alias' do
      it 'adds --force flag' do
        expect_command_capturing('branch', '--force', '--', 'feature-branch')
          .and_return(command_result(''))

        command.call('feature-branch', f: true)
      end
    end

    context 'with :create_reflog option' do
      context 'when true' do
        it 'adds --create-reflog flag' do
          expect_command_capturing('branch', '--create-reflog', '--', 'feature-branch')
            .and_return(command_result(''))

          command.call('feature-branch', create_reflog: true)
        end
      end

      context 'when :no_create_reflog is true' do
        it 'adds --no-create-reflog flag' do
          expect_command_capturing('branch', '--no-create-reflog', '--', 'feature-branch')
            .and_return(command_result(''))

          command.call('feature-branch', no_create_reflog: true)
        end
      end
    end

    context 'with :recurse_submodules option' do
      it 'adds --recurse-submodules flag' do
        expect_command_capturing('branch', '--recurse-submodules', '--', 'feature-branch')
          .and_return(command_result(''))

        command.call('feature-branch', recurse_submodules: true)
      end
    end

    context 'with :quiet option' do
      it 'adds --quiet flag' do
        expect_command_capturing('branch', '--quiet', '--', 'feature-branch')
          .and_return(command_result(''))

        command.call('feature-branch', quiet: true)
      end
    end

    context 'with :q short option alias' do
      it 'adds --quiet flag' do
        expect_command_capturing('branch', '--quiet', '--', 'feature-branch')
          .and_return(command_result(''))

        command.call('feature-branch', q: true)
      end
    end

    context 'with :track option' do
      context 'when true' do
        it 'adds --track flag' do
          expect_command_capturing('branch', '--track', '--', 'feature-branch', 'origin/main')
            .and_return(command_result(''))

          command.call('feature-branch', 'origin/main', track: true)
        end
      end

      context 'when :no_track is true' do
        it 'adds --no-track flag' do
          expect_command_capturing('branch', '--no-track', '--', 'feature-branch', 'origin/main')
            .and_return(command_result(''))

          command.call('feature-branch', 'origin/main', no_track: true)
        end
      end

      context 'when "direct"' do
        it 'adds --track=direct flag' do
          expect_command_capturing('branch', '--track=direct', '--', 'feature-branch', 'origin/main')
            .and_return(command_result(''))

          command.call('feature-branch', 'origin/main', track: 'direct')
        end
      end

      context 'when "inherit"' do
        it 'adds --track=inherit flag' do
          expect_command_capturing('branch', '--track=inherit', '--', 'feature-branch', 'origin/main')
            .and_return(command_result(''))

          command.call('feature-branch', 'origin/main', track: 'inherit')
        end
      end
    end

    context 'with :t short option alias' do
      it 'adds --track flag when true' do
        expect_command_capturing('branch', '--track', '--', 'feature-branch', 'origin/main')
          .and_return(command_result(''))

        command.call('feature-branch', 'origin/main', t: true)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in correct order' do
        expect_command_capturing(
          'branch', '--track', '--force', '--create-reflog',
          '--', 'feature-branch', 'origin/main'
        ).and_return(command_result(''))

        command.call('feature-branch', 'origin/main', force: true, create_reflog: true, track: true)
      end

      it 'combines force with no-track' do
        expect_command_capturing('branch', '--no-track', '--force', '--', 'feature-branch', 'main')
          .and_return(command_result(''))

        command.call('feature-branch', 'main', force: true, no_track: true)
      end
    end

    context 'with nil start_point' do
      it 'omits the start point from the command' do
        expect_command_capturing('branch', '--', 'feature-branch')
          .and_return(command_result(''))

        command.call('feature-branch', nil)
      end

      it 'omits the start point when options are provided' do
        expect_command_capturing('branch', '--force', '--', 'feature-branch')
          .and_return(command_result(''))

        command.call('feature-branch', nil, force: true)
      end
    end
  end
end
