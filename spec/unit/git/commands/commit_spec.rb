# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Commands::Commit do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a simple message' do
      it 'commits with the given message' do
        expected_result = command_result
        expect(execution_context).to receive(:command).with('commit', '--message=Initial commit')
                                                      .and_return(expected_result)

        result = command.call(message: 'Initial commit')

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :all option' do
      it 'includes the --all flag' do
        expect(execution_context).to receive(:command).with('commit', '--all', '--message=Add all changes')

        command.call(message: 'Add all changes', all: true)
      end

      it 'also accepts :add_all as an alias' do
        expect(execution_context).to receive(:command).with('commit', '--all', '--message=Add all changes')

        command.call(message: 'Add all changes', add_all: true)
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command).with('commit', '--message=Message')

        command.call(message: 'Message', all: false)
      end
    end

    context 'with the :allow_empty option' do
      it 'includes the --allow-empty flag' do
        expect(execution_context).to receive(:command).with('commit', '--allow-empty', '--message=Empty commit')

        command.call(message: 'Empty commit', allow_empty: true)
      end
    end

    context 'with the :allow_empty_message option' do
      it 'includes the --allow-empty-message flag without a message' do
        expect(execution_context).to receive(:command).with('commit', '--allow-empty-message')

        command.call(allow_empty_message: true)
      end
    end

    context 'with the :no_verify option' do
      it 'includes the --no-verify flag' do
        expect(execution_context).to receive(:command).with('commit', '--no-verify', '--message=Skip hooks')

        command.call(message: 'Skip hooks', no_verify: true)
      end
    end

    context 'with the :author option' do
      it 'includes the --author flag with the specified value' do
        expect(execution_context).to receive(:command).with(
          'commit',
          '--author=John Doe <john@example.com>',
          '--message=Authored commit'
        )

        command.call(message: 'Authored commit', author: 'John Doe <john@example.com>')
      end
    end

    context 'with the :date option' do
      it 'includes the --date flag with the specified value' do
        expect(execution_context).to receive(:command).with(
          'commit',
          '--message=Dated commit',
          '--date=2023-01-15T10:30:00'
        )

        command.call(message: 'Dated commit', date: '2023-01-15T10:30:00')
      end
    end

    context 'with the :amend option' do
      it 'includes --amend and --no-edit flags' do
        expect(execution_context).to receive(:command).with('commit', '--amend', '--no-edit')

        command.call(amend: true)
      end

      it 'does not include the flags when false' do
        expect(execution_context).to receive(:command).with('commit', '--message=Normal commit')

        command.call(message: 'Normal commit', amend: false)
      end
    end

    context 'with GPG signing options' do
      context 'when :gpg_sign is true' do
        it 'includes --gpg-sign flag' do
          expect(execution_context).to receive(:command).with('commit', '--message=Signed commit', '--gpg-sign')

          command.call(message: 'Signed commit', gpg_sign: true)
        end
      end

      context 'when :gpg_sign is a key ID' do
        it 'includes --gpg-sign with the key ID' do
          expect(execution_context).to receive(:command).with(
            'commit',
            '--message=Signed commit',
            '--gpg-sign=ABCD1234'
          )

          command.call(message: 'Signed commit', gpg_sign: 'ABCD1234')
        end
      end

      context 'when :gpg_sign is false' do
        it 'includes --no-gpg-sign flag' do
          expect(execution_context).to receive(:command).with('commit', '--message=Unsigned commit', '--no-gpg-sign')

          command.call(message: 'Unsigned commit', gpg_sign: false)
        end
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags' do
        expect(execution_context).to receive(:command).with(
          'commit',
          '--all',
          '--no-verify',
          '--author=Jane <jane@example.com>',
          '--message=Combined options'
        )

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
