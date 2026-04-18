# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/fsck'

RSpec.describe Git::Commands::Fsck do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  # Helper to mock command call - accepts any keyword arguments
  def mock_command(*args, stdout: '', stderr: '', exitstatus: 0)
    allow(execution_context).to receive(:command_capturing)
      .with(*args, raise_on_failure: false)
      .and_return(command_result(stdout, stderr: stderr, exitstatus: exitstatus))
  end

  describe '#call' do
    context 'with default arguments' do
      it 'runs fsck with no extra flags' do
        expected_result = command_result('')
        expect_command_capturing('fsck').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :progress option' do
      it 'includes --progress when true' do
        expect_command_capturing('fsck', '--progress').and_return(command_result(''))

        command.call(progress: true)
      end

      it 'includes --no-progress when false' do
        expect_command_capturing('fsck', '--no-progress').and_return(command_result(''))

        command.call(progress: false)
      end
    end

    context 'with specific objects' do
      it 'includes the object identifiers' do
        expect_command_capturing('fsck', 'abc1234', 'def5678').and_return(command_result(''))

        command.call('abc1234', 'def5678')
      end
    end

    context 'with the :unreachable option' do
      it 'includes the --unreachable flag' do
        expect_command_capturing('fsck', '--unreachable').and_return(command_result(''))

        command.call(unreachable: true)
      end
    end

    context 'with the :verbose option' do
      it 'includes the --verbose flag' do
        expect_command_capturing('fsck', '--verbose').and_return(command_result(''))

        command.call(verbose: true)
      end
    end

    context 'with the :strict option' do
      it 'includes the --strict flag' do
        expect_command_capturing('fsck', '--strict').and_return(command_result(''))

        command.call(strict: true)
      end
    end

    context 'with the :connectivity_only option' do
      it 'includes the --connectivity-only flag' do
        expect_command_capturing('fsck', '--connectivity-only').and_return(command_result(''))

        command.call(connectivity_only: true)
      end
    end

    context 'with the :root option' do
      it 'includes the --root flag' do
        expect_command_capturing('fsck', '--root').and_return(command_result(''))

        command.call(root: true)
      end
    end

    context 'with the :tags option' do
      it 'includes the --tags flag' do
        expect_command_capturing('fsck', '--tags').and_return(command_result(''))

        command.call(tags: true)
      end
    end

    context 'with the :cache option' do
      it 'includes the --cache flag' do
        expect_command_capturing('fsck', '--cache').and_return(command_result(''))

        command.call(cache: true)
      end
    end

    context 'with the :no_reflogs option' do
      it 'includes the --no-reflogs flag' do
        expect_command_capturing('fsck', '--no-reflogs').and_return(command_result(''))

        command.call(no_reflogs: true)
      end
    end

    context 'with the :lost_found option' do
      it 'includes the --lost-found flag' do
        expect_command_capturing('fsck', '--lost-found').and_return(command_result(''))

        command.call(lost_found: true)
      end
    end

    context 'with boolean_negatable options' do
      context ':dangling' do
        it 'includes --dangling when true' do
          expect_command_capturing('fsck', '--dangling').and_return(command_result(''))

          command.call(dangling: true)
        end

        it 'includes --no-dangling when false' do
          expect_command_capturing('fsck', '--no-dangling').and_return(command_result(''))

          command.call(dangling: false)
        end
      end

      context ':full' do
        it 'includes --full when true' do
          expect_command_capturing('fsck', '--full').and_return(command_result(''))

          command.call(full: true)
        end

        it 'includes --no-full when false' do
          expect_command_capturing('fsck', '--no-full').and_return(command_result(''))

          command.call(full: false)
        end
      end

      context ':name_objects' do
        it 'includes --name-objects when true' do
          expect_command_capturing('fsck', '--name-objects').and_return(command_result(''))

          command.call(name_objects: true)
        end

        it 'includes --no-name-objects when false' do
          expect_command_capturing('fsck', '--no-name-objects').and_return(command_result(''))

          command.call(name_objects: false)
        end
      end

      context ':references' do
        it 'includes --references when true' do
          expect_command_capturing('fsck', '--references').and_return(command_result(''))

          command.call(references: true)
        end

        it 'includes --no-references when false' do
          expect_command_capturing('fsck', '--no-references').and_return(command_result(''))

          command.call(references: false)
        end
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags' do
        expect_command_capturing('fsck', '--unreachable', '--full',
                                 '--strict').and_return(command_result(''))

        command.call(unreachable: true, strict: true, full: true)
      end
    end

    context 'with objects and options combined' do
      it 'includes both objects and flags' do
        expect_command_capturing('fsck', '--strict', 'abc1234').and_return(command_result(''))

        command.call('abc1234', strict: true)
      end
    end

    context 'exit code handling' do
      it 'handles exit code 0 (no issues)' do
        mock_command('fsck')
        result = command.call
        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'handles exit code 1 (errors found)' do
        output = "missing tree 1234567890abcdef1234567890abcdef12345678\n"
        mock_command('fsck', stdout: output, exitstatus: 1)
        result = command.call
        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'handles exit code 2 (missing objects)' do
        output = "missing blob abcdef1234567890abcdef1234567890abcdef12\n"
        mock_command('fsck', stdout: output, exitstatus: 2)
        result = command.call
        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'handles exit code 4 (warnings)' do
        output = "warning in commit 1234567890abcdef1234567890abcdef12345678: bad date\n"
        mock_command('fsck', stdout: output, exitstatus: 4)
        result = command.call
        expect(result).to be_a(Git::CommandLineResult)
      end

      # Exit codes are bit flags that can be combined
      it 'handles exit code 3 (errors + missing)' do
        output = <<~OUTPUT
          missing tree 1111111111111111111111111111111111111111
          missing blob 2222222222222222222222222222222222222222
        OUTPUT
        mock_command('fsck', stdout: output, exitstatus: 3)
        result = command.call
        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'handles exit code 5 (errors + warnings)' do
        output = <<~OUTPUT
          missing tree 1111111111111111111111111111111111111111
          warning in commit 2222222222222222222222222222222222222222: bad date
        OUTPUT
        mock_command('fsck', stdout: output, exitstatus: 5)
        result = command.call
        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'handles exit code 6 (missing + warnings)' do
        output = <<~OUTPUT
          missing blob 1111111111111111111111111111111111111111
          warning in commit 2222222222222222222222222222222222222222: bad date
        OUTPUT
        mock_command('fsck', stdout: output, exitstatus: 6)
        result = command.call
        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'handles exit code 7 (errors + missing + warnings)' do
        output = <<~OUTPUT
          missing tree 1111111111111111111111111111111111111111
          missing blob 2222222222222222222222222222222222222222
          warning in commit 3333333333333333333333333333333333333333: bad date
        OUTPUT
        mock_command('fsck', stdout: output, exitstatus: 7)
        result = command.call
        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'raises for exit code > 7 (fatal errors)' do
        mock_command('fsck', stderr: 'fatal: not a git repository', exitstatus: 128)
        expect { command.call }.to raise_error(Git::FailedError)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(invalid_option: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :invalid_option/)
        )
      end
    end
  end
end
