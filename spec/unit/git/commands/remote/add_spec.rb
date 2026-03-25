# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/add'

RSpec.describe Git::Commands::Remote::Add do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with name and url' do
      it 'passes the remote name and url' do
        expected_result = command_result
        expect_command_capturing('remote', 'add', '--', 'origin', 'https://example.com/repo.git').and_return(expected_result)

        result = command.call('origin', 'https://example.com/repo.git')

        expect(result).to eq(expected_result)
      end
    end

    context 'with :track option' do
      it 'includes --track with a single branch' do
        expect_command_capturing('remote', 'add', '--track', 'main', '--', 'origin', 'https://example.com/repo.git')
          .and_return(command_result)

        command.call('origin', 'https://example.com/repo.git', track: 'main')
      end

      it 'repeats --track for multiple branches' do
        expect_command_capturing(
          'remote', 'add', '--track', 'main', '--track', 'develop', '--', 'origin', 'https://example.com/repo.git'
        ).and_return(command_result)

        command.call('origin', 'https://example.com/repo.git', track: %w[main develop])
      end

      it 'accepts :t alias' do
        expect_command_capturing('remote', 'add', '--track', 'main', '--', 'origin', 'https://example.com/repo.git')
          .and_return(command_result)

        command.call('origin', 'https://example.com/repo.git', t: 'main')
      end
    end

    context 'with :master option' do
      it 'includes --master' do
        expect_command_capturing('remote', 'add', '--master', 'main', '--', 'origin', 'https://example.com/repo.git')
          .and_return(command_result)

        command.call('origin', 'https://example.com/repo.git', master: 'main')
      end

      it 'accepts :m alias' do
        expect_command_capturing('remote', 'add', '--master', 'main', '--', 'origin', 'https://example.com/repo.git')
          .and_return(command_result)

        command.call('origin', 'https://example.com/repo.git', m: 'main')
      end
    end

    context 'with :fetch option' do
      it 'includes --fetch' do
        expect_command_capturing('remote', 'add', '--fetch', '--', 'origin', 'https://example.com/repo.git')
          .and_return(command_result)

        command.call('origin', 'https://example.com/repo.git', fetch: true)
      end

      it 'accepts :f alias' do
        expect_command_capturing('remote', 'add', '--fetch', '--', 'origin', 'https://example.com/repo.git')
          .and_return(command_result)

        command.call('origin', 'https://example.com/repo.git', f: true)
      end
    end

    context 'with :tags option' do
      it 'includes --tags when true' do
        expect_command_capturing('remote', 'add', '--tags', '--', 'origin', 'https://example.com/repo.git')
          .and_return(command_result)

        command.call('origin', 'https://example.com/repo.git', tags: true)
      end

      it 'includes --no-tags when false' do
        expect_command_capturing('remote', 'add', '--no-tags', '--', 'origin', 'https://example.com/repo.git')
          .and_return(command_result)

        command.call('origin', 'https://example.com/repo.git', tags: false)
      end
    end

    context 'with :mirror option' do
      it 'includes --mirror=<mode>' do
        expect_command_capturing('remote', 'add', '--mirror=fetch', '--', 'origin', 'https://example.com/repo.git')
          .and_return(command_result)

        command.call('origin', 'https://example.com/repo.git', mirror: 'fetch')
      end
    end

    context 'with end-of-options separator' do
      it 'includes -- before the name and url operands' do
        expect_command_capturing('remote', 'add', '--', '-weirdname', 'https://example.com/repo.git')
          .and_return(command_result)

        command.call('-weirdname', 'https://example.com/repo.git')
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when name is missing' do
        expect { command.call }.to raise_error(ArgumentError, /name is required/)
      end

      it 'raises ArgumentError when url is missing' do
        expect { command.call('origin') }.to raise_error(ArgumentError, /url is required/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('origin', 'https://example.com/repo.git', prune: true) }
          .to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
