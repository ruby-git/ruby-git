# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Commands::Rm do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a single file path' do
      it 'removes the specified file' do
        expected_result = command_result
        expect(execution_context).to receive(:command).with('rm', '--', 'file.txt')
                                                      .and_return(expected_result)

        result = command.call('file.txt')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple file paths as an array' do
      it 'removes all specified files' do
        expect(execution_context).to receive(:command).with('rm', '--', 'file1.txt', 'file2.txt')

        command.call(%w[file1.txt file2.txt])
      end
    end

    context 'with the :force option' do
      it 'includes the -f flag when true' do
        expect(execution_context).to receive(:command).with('rm', '-f', '--', 'file.txt')

        command.call('file.txt', force: true)
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command).with('rm', '--', 'file.txt')

        command.call('file.txt', force: false)
      end
    end

    context 'with the :recursive option' do
      it 'includes the -r flag when true' do
        expect(execution_context).to receive(:command).with('rm', '-r', '--', 'directory')

        command.call('directory', recursive: true)
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command).with('rm', '--', 'file.txt')

        command.call('file.txt', recursive: false)
      end
    end

    context 'with the :cached option' do
      it 'includes the --cached flag when true' do
        expect(execution_context).to receive(:command).with('rm', '--cached', '--', 'file.txt')

        command.call('file.txt', cached: true)
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command).with('rm', '--', 'file.txt')

        command.call('file.txt', cached: false)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags' do
        expect(execution_context).to receive(:command).with('rm', '-f', '-r', '--cached', '--', 'directory')

        command.call('directory', force: true, recursive: true, cached: true)
      end
    end

    context 'with paths containing special characters' do
      it 'handles paths with spaces' do
        expect(execution_context).to receive(:command).with('rm', '--', 'path/to/my file.txt')

        command.call('path/to/my file.txt')
      end

      it 'handles paths with unicode characters' do
        expect(execution_context).to receive(:command).with('rm', '--', 'path/to/файл.txt')

        command.call('path/to/файл.txt')
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for nil (treated as not provided)' do
        expect { command.call(nil) }.to raise_error(ArgumentError, /at least one value is required/)
      end

      it 'raises ArgumentError for empty array' do
        expect { command.call([]) }.to raise_error(ArgumentError, /at least one value is required for paths/)
      end

      it 'raises ArgumentError for no arguments' do
        expect { command.call }.to raise_error(ArgumentError, /at least one value is required for paths/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('file.txt', invalid_option: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :invalid_option/)
        )
      end
    end
  end
end
