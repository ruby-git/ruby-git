# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/revert/start'

RSpec.describe Git::Commands::Revert::Start do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a single commit' do
      it 'calls git revert with the commit ref' do
        expected_result = command_result
        expect_command_capturing('revert', '--', 'abc123').and_return(expected_result)

        result = command.call('abc123')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple commits' do
      it 'includes all commit refs' do
        expect_command_capturing('revert', '--', 'abc123', 'def456').and_return(command_result(''))
        command.call('abc123', 'def456')
      end
    end

    context 'with :edit option' do
      it 'adds --edit when true' do
        expect_command_capturing('revert', '--edit', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', edit: true)
      end

      it 'adds --no-edit when false' do
        expect_command_capturing('revert', '--no-edit', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', edit: false)
      end

      it 'supports the :e alias' do
        expect_command_capturing('revert', '--edit', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', e: true)
      end
    end

    context 'with :cleanup option' do
      it 'adds --cleanup=<mode>' do
        expect_command_capturing('revert', '--cleanup=strip', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', cleanup: 'strip')
      end
    end

    context 'with :no_commit option' do
      it 'adds --no-commit when true' do
        expect_command_capturing('revert', '--no-commit', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', no_commit: true)
      end

      it 'supports the :n alias' do
        expect_command_capturing('revert', '--no-commit', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', n: true)
      end
    end

    context 'with :gpg_sign option' do
      it 'adds --gpg-sign when true' do
        expect_command_capturing('revert', '--gpg-sign', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', gpg_sign: true)
      end

      it 'adds --no-gpg-sign when false' do
        expect_command_capturing('revert', '--no-gpg-sign', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', gpg_sign: false)
      end

      it 'adds --gpg-sign=<keyid> when given a key ID string' do
        expect_command_capturing('revert', '--gpg-sign=ABCDEF01', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', gpg_sign: 'ABCDEF01')
      end

      it 'supports the :S alias' do
        expect_command_capturing('revert', '--gpg-sign', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', S: true)
      end
    end

    context 'with :signoff option' do
      it 'adds --signoff when true' do
        expect_command_capturing('revert', '--signoff', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', signoff: true)
      end

      it 'adds --no-signoff when false' do
        expect_command_capturing('revert', '--no-signoff', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', signoff: false)
      end

      it 'supports the :s alias' do
        expect_command_capturing('revert', '--signoff', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', s: true)
      end
    end

    context 'with :strategy option' do
      it 'adds --strategy=<name>' do
        expect_command_capturing('revert', '--strategy=ort', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', strategy: 'ort')
      end
    end

    context 'with :strategy_option option' do
      it 'adds --strategy-option=<value>' do
        expect_command_capturing('revert', '--strategy-option=theirs', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', strategy_option: 'theirs')
      end

      it 'supports multiple strategy options as an array' do
        expect_command_capturing(
          'revert', '--strategy-option=ours', '--strategy-option=patience', '--', 'abc123'
        ).and_return(command_result(''))
        command.call('abc123', strategy_option: %w[ours patience])
      end

      it 'supports the :X alias' do
        expect_command_capturing('revert', '--strategy-option=theirs', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', X: 'theirs')
      end
    end

    context 'with :rerere_autoupdate option' do
      it 'adds --rerere-autoupdate when true' do
        expect_command_capturing('revert', '--rerere-autoupdate', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', rerere_autoupdate: true)
      end

      it 'adds --no-rerere-autoupdate when false' do
        expect_command_capturing('revert', '--no-rerere-autoupdate', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', rerere_autoupdate: false)
      end
    end

    context 'with :mainline option' do
      it 'adds --mainline <n>' do
        expect_command_capturing('revert', '--mainline', '1', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', mainline: 1)
      end

      it 'supports the :m alias' do
        expect_command_capturing('revert', '--mainline', '2', '--', 'abc123').and_return(command_result(''))
        command.call('abc123', m: 2)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in the correct order' do
        expect_command_capturing(
          'revert', '--no-commit', '--signoff', '--', 'abc123', 'def456'
        ).and_return(command_result(''))
        command.call('abc123', 'def456', no_commit: true, signoff: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when no commits are provided' do
        expect { command.call }.to raise_error(ArgumentError, /at least one value is required for commit/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('abc123', unknown_opt: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
