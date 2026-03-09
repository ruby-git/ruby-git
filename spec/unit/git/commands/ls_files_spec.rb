# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/ls_files'

RSpec.describe Git::Commands::LsFiles do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git ls-files with no extra arguments and returns the result' do
        expected_result = command_result("100644 abc123 0\tfile.txt")
        expect_command_capturing('ls-files').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a path operand' do
      it 'passes the path as a positional argument' do
        expected_result = command_result("100644 abc123 0\tlib/foo.rb")
        expect_command_capturing('ls-files', 'lib/').and_return(expected_result)

        result = command.call('lib/')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple path operands' do
      it 'passes all paths as positional arguments' do
        expect_command_capturing('ls-files', 'lib/', 'spec/').and_return(command_result(''))

        command.call('lib/', 'spec/')
      end
    end

    context 'with :stage option' do
      it 'includes --stage flag' do
        expect_command_capturing('ls-files', '--stage').and_return(command_result("100644 abc123 0\tfile.txt"))

        command.call(stage: true)
      end
    end

    context 'with :stage option and a path' do
      it 'includes --stage flag and path operand' do
        staged_output = "100644 abc123 0\tlib/foo.rb"
        expect_command_capturing('ls-files', '--stage', 'lib/').and_return(command_result(staged_output))

        command.call('lib/', stage: true)
      end
    end

    context 'with :cached option' do
      it 'includes --cached flag' do
        expect_command_capturing('ls-files', '--cached').and_return(command_result("file.txt\n"))

        command.call(cached: true)
      end
    end

    context 'with :deleted option' do
      it 'includes --deleted flag' do
        expect_command_capturing('ls-files', '--deleted').and_return(command_result(''))

        command.call(deleted: true)
      end
    end

    context 'with :modified option' do
      it 'includes --modified flag' do
        expect_command_capturing('ls-files', '--modified').and_return(command_result(''))

        command.call(modified: true)
      end
    end

    context 'with :others option' do
      it 'includes --others flag' do
        expect_command_capturing('ls-files', '--others').and_return(command_result(''))

        command.call(others: true)
      end
    end

    context 'with :unmerged option' do
      it 'includes --unmerged flag' do
        expect_command_capturing('ls-files', '--unmerged').and_return(command_result(''))

        command.call(unmerged: true)
      end
    end

    context 'with :ignored option' do
      it 'includes --ignored flag' do
        expect_command_capturing('ls-files', '--ignored').and_return(command_result(''))

        command.call(ignored: true)
      end
    end

    context 'with :full_name option' do
      it 'includes --full-name flag' do
        expect_command_capturing('ls-files', '--full-name').and_return(command_result(''))

        command.call(full_name: true)
      end
    end

    context 'with :exclude_standard option' do
      it 'includes --exclude-standard flag' do
        expect_command_capturing('ls-files', '--exclude-standard').and_return(command_result(''))

        command.call(exclude_standard: true)
      end
    end

    context 'with :error_unmatch option' do
      it 'includes --error-unmatch flag' do
        expect_command_capturing('ls-files', '--error-unmatch').and_return(command_result(''))

        command.call(error_unmatch: true)
      end
    end

    context 'with combined options and path' do
      it 'combines stage flag and path correctly' do
        expect_command_capturing('ls-files', '--stage', '--full-name', 'src/').and_return(command_result(''))

        command.call('src/', stage: true, full_name: true)
      end
    end
  end
end
