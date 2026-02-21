# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Commands::Add do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with default arguments' do
      it 'adds nothing' do
        expected_result = command_result
        expect_command('add').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a single file path' do
      it 'adds the specified file' do
        expect_command('add', '--', 'path/to/file.rb').and_return(command_result)

        command.call('path/to/file.rb')
      end
    end

    context 'with multiple file paths as an array' do
      it 'adds all specified files' do
        expect_command('add', '--', 'file1.rb', 'file2.rb', 'file3.rb').and_return(command_result)

        command.call(%w[file1.rb file2.rb file3.rb])
      end
    end

    context 'with the :dry_run option' do
      it 'includes the --dry-run flag' do
        expect_command('add', '--dry-run', '--', 'file.rb').and_return(command_result)

        command.call('file.rb', dry_run: true)
      end

      it 'accepts the :n alias' do
        expect_command('add', '--dry-run', '--', 'file.rb').and_return(command_result)

        command.call('file.rb', n: true)
      end

      it 'does not include the flag when false' do
        expect_command('add', '--', 'file.rb').and_return(command_result)

        command.call('file.rb', dry_run: false)
      end
    end

    context 'with the :force option' do
      it 'includes the --force flag' do
        expect_command('add', '--force', '--', 'ignored_file.txt').and_return(command_result)

        command.call('ignored_file.txt', force: true)
      end

      it 'does not include the flag when false' do
        expect_command('add', '--', 'file.txt').and_return(command_result)

        command.call('file.txt', force: false)
      end
    end

    context 'with the :update option' do
      it 'includes the --update flag' do
        expect_command('add', '--update', '--', 'file.rb').and_return(command_result)

        command.call('file.rb', update: true)
      end

      it 'accepts the :u alias' do
        expect_command('add', '--update', '--', 'file.rb').and_return(command_result)

        command.call('file.rb', u: true)
      end

      it 'does not include the flag when false' do
        expect_command('add', '--', 'file.rb').and_return(command_result)

        command.call('file.rb', update: false)
      end
    end

    context 'with the :all option' do
      it 'includes the --all flag when true' do
        expect_command('add', '--all', '--', '.').and_return(command_result)

        command.call('.', all: true)
      end

      it 'includes --no-all when false (negatable flag)' do
        expect_command('add', '--no-all', '--', '.').and_return(command_result)

        command.call('.', all: false)
      end

      it 'omits the flag when not provided' do
        expect_command('add', '--', '.').and_return(command_result)

        command.call('.')
      end
    end

    context 'with the :intent_to_add option' do
      it 'includes the --intent-to-add flag' do
        expect_command('add', '--intent-to-add', '--', 'new_file.rb').and_return(command_result)

        command.call('new_file.rb', intent_to_add: true)
      end

      it 'accepts the :N alias' do
        expect_command('add', '--intent-to-add', '--', 'new_file.rb').and_return(command_result)

        command.call('new_file.rb', N: true)
      end

      it 'does not include the flag when false' do
        expect_command('add', '--', 'new_file.rb').and_return(command_result)

        command.call('new_file.rb', intent_to_add: false)
      end
    end

    context 'with the :ignore_errors option' do
      it 'includes the --ignore-errors flag' do
        expect_command('add', '--ignore-errors', '--', 'file.rb').and_return(command_result)

        command.call('file.rb', ignore_errors: true)
      end

      it 'does not include the flag when false' do
        expect_command('add', '--', 'file.rb').and_return(command_result)

        command.call('file.rb', ignore_errors: false)
      end
    end

    context 'with the :sparse option' do
      it 'includes the --sparse flag' do
        expect_command('add', '--sparse', '--', 'file.rb').and_return(command_result)

        command.call('file.rb', sparse: true)
      end

      it 'does not include the flag when false' do
        expect_command('add', '--', 'file.rb').and_return(command_result)

        command.call('file.rb', sparse: false)
      end
    end

    context 'with the :refresh option' do
      it 'includes the --refresh flag' do
        expect_command('add', '--refresh').and_return(command_result)

        command.call(refresh: true)
      end

      it 'does not include the flag when false' do
        expect_command('add').and_return(command_result)

        command.call(refresh: false)
      end
    end

    context 'with the :ignore_missing option' do
      it 'includes the --ignore-missing flag' do
        expect_command('add', '--dry-run', '--ignore-missing', '--', 'file.rb').and_return(command_result)

        command.call('file.rb', dry_run: true, ignore_missing: true)
      end

      it 'does not include the flag when false' do
        expect_command('add', '--', 'file.rb').and_return(command_result)

        command.call('file.rb', ignore_missing: false)
      end
    end

    context 'with the :renormalize option' do
      it 'includes the --renormalize flag' do
        expect_command('add', '--renormalize').and_return(command_result)

        command.call(renormalize: true)
      end

      it 'does not include the flag when false' do
        expect_command('add').and_return(command_result)

        command.call(renormalize: false)
      end
    end

    context 'with the :chmod option' do
      it 'includes --chmod=+x' do
        expect_command('add', '--chmod=+x', '--', 'file.rb').and_return(command_result)

        command.call('file.rb', chmod: '+x')
      end

      it 'includes --chmod=-x' do
        expect_command('add', '--chmod=-x', '--', 'file.rb').and_return(command_result)

        command.call('file.rb', chmod: '-x')
      end
    end

    context 'with the :pathspec_from_file option' do
      it 'includes --pathspec-from-file with the given path' do
        expect_command('add', '--pathspec-from-file=paths.txt').and_return(command_result)

        command.call(pathspec_from_file: 'paths.txt')
      end

      it 'accepts stdin via -' do
        expect_command('add', '--pathspec-from-file=-').and_return(command_result)

        command.call(pathspec_from_file: '-')
      end
    end

    context 'with the :pathspec_file_nul option' do
      it 'includes --pathspec-file-nul alongside --pathspec-from-file' do
        expect_command('add', '--pathspec-from-file=paths.txt', '--pathspec-file-nul').and_return(command_result)

        command.call(pathspec_from_file: 'paths.txt', pathspec_file_nul: true)
      end
    end

    context 'with conflicting options' do
      it 'raises ArgumentError when :all and :update are both given' do
        expect { command.call('.', all: true, update: true) }.to(
          raise_error(ArgumentError, /:all.*:update|:update.*:all/)
        )
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags' do
        expect_command('add', '--force', '--all', '--', '.').and_return(command_result)

        command.call('.', all: true, force: true)
      end
    end

    context 'with paths containing special characters' do
      it 'handles paths with spaces' do
        expect_command('add', '--', 'path/to/my file.rb').and_return(command_result)

        command.call('path/to/my file.rb')
      end

      it 'handles paths with unicode characters' do
        expect_command('add', '--', 'path/to/файл.rb').and_return(command_result)

        command.call('path/to/файл.rb')
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('.', invalid_option: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :invalid_option/)
        )
      end
    end
  end
end
