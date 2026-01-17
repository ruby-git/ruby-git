# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Commands::Add do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with default arguments' do
      it 'adds the current directory' do
        expect(execution_context).to receive(:command).with('add', '--', '.')

        command.call
      end
    end

    context 'with a single file path' do
      it 'adds the specified file' do
        expect(execution_context).to receive(:command).with('add', '--', 'path/to/file.rb')

        command.call('path/to/file.rb')
      end
    end

    context 'with multiple file paths as an array' do
      it 'adds all specified files' do
        expect(execution_context).to receive(:command).with('add', '--', 'file1.rb', 'file2.rb', 'file3.rb')

        command.call(%w[file1.rb file2.rb file3.rb])
      end
    end

    context 'with the :all option' do
      it 'includes the --all flag' do
        expect(execution_context).to receive(:command).with('add', '--all', '--', '.')

        command.call('.', all: true)
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command).with('add', '--', '.')

        command.call('.', all: false)
      end
    end

    context 'with the :force option' do
      it 'includes the --force flag' do
        expect(execution_context).to receive(:command).with('add', '--force', '--', 'ignored_file.txt')

        command.call('ignored_file.txt', force: true)
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command).with('add', '--', 'file.txt')

        command.call('file.txt', force: false)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags' do
        expect(execution_context).to receive(:command).with('add', '--all', '--force', '--', '.')

        command.call('.', all: true, force: true)
      end
    end

    context 'with paths containing special characters' do
      it 'handles paths with spaces' do
        expect(execution_context).to receive(:command).with('add', '--', 'path/to/my file.rb')

        command.call('path/to/my file.rb')
      end

      it 'handles paths with unicode characters' do
        expect(execution_context).to receive(:command).with('add', '--', 'path/to/файл.rb')

        command.call('path/to/файл.rb')
      end
    end

    context 'with unsupported options' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('.', invalid_option: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :invalid_option/)
        )
      end
    end
  end
end
