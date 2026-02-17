# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Commands::Commit do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a simple message' do
      it 'commits with the given message' do
        expected_result = command_result
        expect_command('commit', '--message=Initial commit').and_return(expected_result)

        result = command.call(message: 'Initial commit')

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :all option' do
      it 'includes the --all flag' do
        expect_command('commit', '--all', '--message=Add all changes').and_return(command_result)

        command.call(message: 'Add all changes', all: true)
      end

      it 'also accepts :add_all as an alias' do
        expect_command('commit', '--all', '--message=Add all changes').and_return(command_result)

        command.call(message: 'Add all changes', add_all: true)
      end

      it 'does not include the flag when false' do
        expect_command('commit', '--message=Message').and_return(command_result)

        command.call(message: 'Message', all: false)
      end
    end

    context 'with the :allow_empty option' do
      it 'includes the --allow-empty flag' do
        expect_command('commit', '--allow-empty', '--message=Empty commit').and_return(command_result)

        command.call(message: 'Empty commit', allow_empty: true)
      end
    end

    context 'with the :allow_empty_message option' do
      it 'includes the --allow-empty-message flag without a message' do
        expect_command('commit', '--allow-empty-message').and_return(command_result)

        command.call(allow_empty_message: true)
      end
    end

    context 'with the :no_verify option' do
      it 'includes the --no-verify flag' do
        expect_command('commit', '--no-verify', '--message=Skip hooks').and_return(command_result)

        command.call(message: 'Skip hooks', no_verify: true)
      end
    end

    context 'with the :author option' do
      it 'includes the --author flag with the specified value' do
        expect_command(
          'commit',
          '--author=John Doe <john@example.com>',
          '--message=Authored commit'
        ).and_return(command_result)

        command.call(message: 'Authored commit', author: 'John Doe <john@example.com>')
      end
    end

    context 'with the :date option' do
      it 'includes the --date flag with the specified value' do
        expect_command(
          'commit',
          '--message=Dated commit',
          '--date=2023-01-15T10:30:00'
        ).and_return(command_result)

        command.call(message: 'Dated commit', date: '2023-01-15T10:30:00')
      end
    end

    context 'with the :amend option' do
      it 'includes --amend and --no-edit flags' do
        expect_command('commit', '--amend', '--no-edit').and_return(command_result)

        command.call(amend: true)
      end

      it 'does not include the flags when false' do
        expect_command('commit', '--message=Normal commit').and_return(command_result)

        command.call(message: 'Normal commit', amend: false)
      end
    end

    context 'with GPG signing options' do
      context 'when :gpg_sign is true' do
        it 'includes --gpg-sign flag' do
          expect_command('commit', '--message=Signed commit', '--gpg-sign').and_return(command_result)

          command.call(message: 'Signed commit', gpg_sign: true)
        end
      end

      context 'when :gpg_sign is a key ID' do
        it 'includes --gpg-sign with the key ID' do
          expect_command(
            'commit',
            '--message=Signed commit',
            '--gpg-sign=ABCD1234'
          ).and_return(command_result)

          command.call(message: 'Signed commit', gpg_sign: 'ABCD1234')
        end
      end

      context 'when :gpg_sign is false' do
        it 'includes --no-gpg-sign flag' do
          expect_command('commit', '--message=Unsigned commit', '--no-gpg-sign').and_return(command_result)

          command.call(message: 'Unsigned commit', gpg_sign: false)
        end
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags' do
        expect_command(
          'commit',
          '--all',
          '--no-verify',
          '--author=Jane <jane@example.com>',
          '--message=Combined options'
        ).and_return(command_result)

        command.call(
          message: 'Combined options',
          all: true,
          no_verify: true,
          author: 'Jane <jane@example.com>'
        )
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when date is not a string' do
        expect { command.call(message: 'Commit', date: Time.now) }.to(
          raise_error(ArgumentError, /The :date option must be a String, but was a Time/)
        )
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call(message: 'Commit', invalid_option: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :invalid_option/)
        )
      end

      it 'raises ArgumentError when both :all and :add_all are provided' do
        expect { command.call(message: 'Commit', all: true, add_all: true) }.to(
          raise_error(ArgumentError, /Conflicting options/)
        )
      end
    end
  end
end
