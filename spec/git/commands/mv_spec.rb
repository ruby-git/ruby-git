# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Commands::Mv do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a single file to move' do
      it 'moves the file to the destination' do
        expect(execution_context).to receive(:command).with('mv', '--', 'old_name.rb', 'new_name.rb')

        command.call('old_name.rb', 'new_name.rb')
      end
    end

    context 'with multiple source files' do
      it 'moves all files to the destination directory' do
        expect(execution_context).to receive(:command).with(
          'mv', '--', 'file1.rb', 'file2.rb', 'file3.rb', 'destination_dir/'
        )

        command.call('file1.rb', 'file2.rb', 'file3.rb', 'destination_dir/')
      end
    end

    context 'with the :force option' do
      it 'includes the --force flag' do
        expect(execution_context).to receive(:command).with('mv', '--force', '--', 'source.rb', 'dest.rb')

        command.call('source.rb', 'dest.rb', force: true)
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command).with('mv', '--', 'source.rb', 'dest.rb')

        command.call('source.rb', 'dest.rb', force: false)
      end
    end

    context 'with the :dry_run option' do
      it 'includes the --dry-run flag' do
        expect(execution_context).to receive(:command).with('mv', '--dry-run', '--', 'source.rb', 'dest.rb')

        command.call('source.rb', 'dest.rb', dry_run: true)
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command).with('mv', '--', 'source.rb', 'dest.rb')

        command.call('source.rb', 'dest.rb', dry_run: false)
      end
    end

    context 'with the :verbose option' do
      it 'includes the --verbose flag' do
        expect(execution_context).to receive(:command).with('mv', '--verbose', '--', 'source.rb', 'dest.rb')

        command.call('source.rb', 'dest.rb', verbose: true)
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command).with('mv', '--', 'source.rb', 'dest.rb')

        command.call('source.rb', 'dest.rb', verbose: false)
      end
    end

    context 'with the :skip_errors option' do
      it 'includes the -k flag' do
        expect(execution_context).to receive(:command).with('mv', '-k', '--', 'source.rb', 'dest.rb')

        command.call('source.rb', 'dest.rb', skip_errors: true)
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command).with('mv', '--', 'source.rb', 'dest.rb')

        command.call('source.rb', 'dest.rb', skip_errors: false)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags' do
        expect(execution_context).to receive(:command).with(
          'mv', '--force', '--dry-run', '--verbose', '--', 'source.rb', 'dest.rb'
        )

        command.call('source.rb', 'dest.rb', force: true, dry_run: true, verbose: true)
      end

      it 'handles force and skip_errors together' do
        expect(execution_context).to receive(:command).with(
          'mv', '--force', '-k', '--', 'file1.rb', 'file2.rb', 'dest_dir/'
        )

        command.call('file1.rb', 'file2.rb', 'dest_dir/', force: true, skip_errors: true)
      end
    end

    context 'with paths containing special characters' do
      it 'handles paths with spaces' do
        expect(execution_context).to receive(:command).with('mv', '--', 'old file.rb', 'new file.rb')

        command.call('old file.rb', 'new file.rb')
      end

      it 'handles paths with unicode characters' do
        expect(execution_context).to receive(:command).with('mv', '--', 'старый.rb', 'новый.rb')

        command.call('старый.rb', 'новый.rb')
      end

      it 'handles paths with special characters' do
        expect(execution_context).to receive(:command).with('mv', '--', 'file[1].rb', 'file(2).rb')

        command.call('file[1].rb', 'file(2).rb')
      end
    end

    context 'with directory paths' do
      it 'moves a directory to a new location' do
        expect(execution_context).to receive(:command).with('mv', '--', 'old_dir/', 'new_dir/')

        command.call('old_dir/', 'new_dir/')
      end

      it 'moves files into an existing directory' do
        expect(execution_context).to receive(:command).with(
          'mv', '--', 'file1.rb', 'file2.rb', 'existing_dir/'
        )

        command.call('file1.rb', 'file2.rb', 'existing_dir/')
      end
    end

    context 'with missing arguments' do
      it 'raises ArgumentError when no arguments provided' do
        expect { command.call }.to(
          raise_error(ArgumentError, /wrong number of arguments/)
        )
      end
    end

    context 'with unsupported options' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('source.rb', 'dest.rb', invalid_option: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :invalid_option/)
        )
      end

      it 'raises ArgumentError for multiple unsupported options' do
        expect { command.call('source.rb', 'dest.rb', bad1: true, bad2: false) }.to(
          raise_error(ArgumentError, /Unsupported options: :bad1, :bad2/)
        )
      end
    end
  end
end
