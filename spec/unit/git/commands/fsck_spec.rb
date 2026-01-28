# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Commands::Fsck do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with default arguments' do
      it 'runs fsck with --no-progress' do
        expect(execution_context).to receive(:command).with('fsck', '--no-progress').and_return('')

        command.call
      end
    end

    context 'with specific objects' do
      it 'includes the object identifiers' do
        expect(execution_context).to receive(:command)
          .with('fsck', '--no-progress', 'abc1234', 'def5678')
          .and_return('')

        command.call('abc1234', 'def5678')
      end
    end

    context 'with the :unreachable option' do
      it 'includes the --unreachable flag' do
        expect(execution_context).to receive(:command)
          .with('fsck', '--no-progress', '--unreachable')
          .and_return('')

        command.call(unreachable: true)
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command)
          .with('fsck', '--no-progress')
          .and_return('')

        command.call(unreachable: false)
      end
    end

    context 'with the :strict option' do
      it 'includes the --strict flag' do
        expect(execution_context).to receive(:command)
          .with('fsck', '--no-progress', '--strict')
          .and_return('')

        command.call(strict: true)
      end
    end

    context 'with the :connectivity_only option' do
      it 'includes the --connectivity-only flag' do
        expect(execution_context).to receive(:command)
          .with('fsck', '--no-progress', '--connectivity-only')
          .and_return('')

        command.call(connectivity_only: true)
      end
    end

    context 'with the :root option' do
      it 'includes the --root flag' do
        expect(execution_context).to receive(:command)
          .with('fsck', '--no-progress', '--root')
          .and_return('')

        command.call(root: true)
      end
    end

    context 'with the :tags option' do
      it 'includes the --tags flag' do
        expect(execution_context).to receive(:command)
          .with('fsck', '--no-progress', '--tags')
          .and_return('')

        command.call(tags: true)
      end
    end

    context 'with the :cache option' do
      it 'includes the --cache flag' do
        expect(execution_context).to receive(:command)
          .with('fsck', '--no-progress', '--cache')
          .and_return('')

        command.call(cache: true)
      end
    end

    context 'with the :no_reflogs option' do
      it 'includes the --no-reflogs flag' do
        expect(execution_context).to receive(:command)
          .with('fsck', '--no-progress', '--no-reflogs')
          .and_return('')

        command.call(no_reflogs: true)
      end
    end

    context 'with the :lost_found option' do
      it 'includes the --lost-found flag' do
        expect(execution_context).to receive(:command)
          .with('fsck', '--no-progress', '--lost-found')
          .and_return('')

        command.call(lost_found: true)
      end
    end

    context 'with boolean_negatable options' do
      context ':dangling' do
        it 'includes --dangling when true' do
          expect(execution_context).to receive(:command)
            .with('fsck', '--no-progress', '--dangling')
            .and_return('')

          command.call(dangling: true)
        end

        it 'includes --no-dangling when false' do
          expect(execution_context).to receive(:command)
            .with('fsck', '--no-progress', '--no-dangling')
            .and_return('')

          command.call(dangling: false)
        end
      end

      context ':full' do
        it 'includes --full when true' do
          expect(execution_context).to receive(:command)
            .with('fsck', '--no-progress', '--full')
            .and_return('')

          command.call(full: true)
        end

        it 'includes --no-full when false' do
          expect(execution_context).to receive(:command)
            .with('fsck', '--no-progress', '--no-full')
            .and_return('')

          command.call(full: false)
        end
      end

      context ':name_objects' do
        it 'includes --name-objects when true' do
          expect(execution_context).to receive(:command)
            .with('fsck', '--no-progress', '--name-objects')
            .and_return('')

          command.call(name_objects: true)
        end

        it 'includes --no-name-objects when false' do
          expect(execution_context).to receive(:command)
            .with('fsck', '--no-progress', '--no-name-objects')
            .and_return('')

          command.call(name_objects: false)
        end
      end

      context ':references' do
        it 'includes --references when true' do
          expect(execution_context).to receive(:command)
            .with('fsck', '--no-progress', '--references')
            .and_return('')

          command.call(references: true)
        end

        it 'includes --no-references when false' do
          expect(execution_context).to receive(:command)
            .with('fsck', '--no-progress', '--no-references')
            .and_return('')

          command.call(references: false)
        end
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags' do
        expect(execution_context).to receive(:command)
          .with('fsck', '--no-progress', '--unreachable', '--strict', '--full')
          .and_return('')

        command.call(unreachable: true, strict: true, full: true)
      end
    end

    context 'with objects and options combined' do
      it 'includes both objects and flags' do
        expect(execution_context).to receive(:command)
          .with('fsck', '--no-progress', '--strict', 'abc1234')
          .and_return('')

        command.call('abc1234', strict: true)
      end
    end

    context 'output parsing' do
      context 'with dangling objects' do
        it 'parses dangling objects correctly' do
          output = "dangling blob 1234567890abcdef1234567890abcdef12345678\n"
          expect(execution_context).to receive(:command).and_return(output)

          result = command.call

          expect(result.dangling.size).to eq(1)
          expect(result.dangling.first.type).to eq(:blob)
          expect(result.dangling.first.oid).to eq('1234567890abcdef1234567890abcdef12345678')
        end

        it 'parses dangling objects with names' do
          output = "dangling blob 1234567890abcdef1234567890abcdef12345678 (HEAD~2:src/file.rb)\n"
          expect(execution_context).to receive(:command).and_return(output)

          result = command.call

          expect(result.dangling.first.name).to eq('HEAD~2:src/file.rb')
        end
      end

      context 'with missing objects' do
        it 'parses missing objects correctly' do
          output = "missing tree abcdef1234567890abcdef1234567890abcdef12\n"
          expect(execution_context).to receive(:command).and_return(output)

          result = command.call

          expect(result.missing.size).to eq(1)
          expect(result.missing.first.type).to eq(:tree)
          expect(result.missing.first.oid).to eq('abcdef1234567890abcdef1234567890abcdef12')
        end
      end

      context 'with unreachable objects' do
        it 'parses unreachable objects correctly' do
          output = "unreachable commit fedcba0987654321fedcba0987654321fedcba09\n"
          expect(execution_context).to receive(:command).and_return(output)

          result = command.call

          expect(result.unreachable.size).to eq(1)
          expect(result.unreachable.first.type).to eq(:commit)
          expect(result.unreachable.first.oid).to eq('fedcba0987654321fedcba0987654321fedcba09')
        end
      end

      context 'with warnings' do
        it 'parses warning lines correctly' do
          output = "warning in commit 1234567890abcdef1234567890abcdef12345678: invalid author/committer\n"
          expect(execution_context).to receive(:command).and_return(output)

          result = command.call

          expect(result.warnings.size).to eq(1)
          expect(result.warnings.first.type).to eq(:commit)
          expect(result.warnings.first.oid).to eq('1234567890abcdef1234567890abcdef12345678')
          expect(result.warnings.first.message).to eq('invalid author/committer')
        end
      end

      context 'with root nodes' do
        it 'parses root lines correctly' do
          output = "root 1234567890abcdef1234567890abcdef12345678\n"
          expect(execution_context).to receive(:command).and_return(output)

          result = command.call

          expect(result.root.size).to eq(1)
          expect(result.root.first.type).to eq(:commit)
          expect(result.root.first.oid).to eq('1234567890abcdef1234567890abcdef12345678')
        end
      end

      context 'with tagged objects' do
        it 'parses tagged lines correctly' do
          output = 'tagged commit abcdef1234567890abcdef1234567890abcdef12 (v1.0.0) in ' \
                   "fedcba0987654321fedcba0987654321fedcba09\n"
          expect(execution_context).to receive(:command).and_return(output)

          result = command.call

          expect(result.tagged.size).to eq(1)
          expect(result.tagged.first.type).to eq(:commit)
          expect(result.tagged.first.oid).to eq('abcdef1234567890abcdef1234567890abcdef12')
          expect(result.tagged.first.name).to eq('v1.0.0')
        end
      end

      context 'with mixed output' do
        it 'parses all types correctly' do
          output = <<~OUTPUT
            dangling blob 1111111111111111111111111111111111111111
            missing tree 2222222222222222222222222222222222222222
            unreachable commit 3333333333333333333333333333333333333333
            warning in commit 4444444444444444444444444444444444444444: bad date
          OUTPUT
          expect(execution_context).to receive(:command).and_return(output)

          result = command.call

          expect(result.dangling.size).to eq(1)
          expect(result.missing.size).to eq(1)
          expect(result.unreachable.size).to eq(1)
          expect(result.warnings.size).to eq(1)
        end
      end

      context 'with empty output' do
        it 'returns an empty result' do
          expect(execution_context).to receive(:command).and_return('')

          result = command.call

          expect(result.empty?).to eq(true)
          expect(result.any_issues?).to eq(false)
        end
      end
    end

    context 'error handling' do
      it 'handles non-zero exit codes for errors' do
        result_double = double('Result',
                               status: double('Status', exitstatus: 1),
                               stdout: 'missing tree abc123',
                               git_cmd: 'git fsck',
                               stderr: '')
        failed_error = Git::FailedError.new(result_double)

        expect(execution_context).to receive(:command).and_raise(failed_error)

        result = command.call
        expect(result).to be_a(Git::FsckResult)
      end

      it 'handles exit code 2 for missing objects' do
        result_double = double('Result',
                               status: double('Status', exitstatus: 2),
                               stdout: 'missing blob def456',
                               git_cmd: 'git fsck',
                               stderr: '')
        failed_error = Git::FailedError.new(result_double)

        expect(execution_context).to receive(:command).and_raise(failed_error)

        result = command.call
        expect(result).to be_a(Git::FsckResult)
      end

      it 'handles exit code 4 for warnings' do
        result_double = double('Result',
                               status: double('Status', exitstatus: 4),
                               stdout: 'warning in commit ghi789: bad date',
                               git_cmd: 'git fsck',
                               stderr: '')
        failed_error = Git::FailedError.new(result_double)

        expect(execution_context).to receive(:command).and_raise(failed_error)

        result = command.call
        expect(result).to be_a(Git::FsckResult)
      end

      it 're-raises errors with unexpected exit codes' do
        result_double = double('Result',
                               status: double('Status', exitstatus: 128),
                               git_cmd: 'git fsck',
                               stderr: '')
        failed_error = Git::FailedError.new(result_double)

        expect(execution_context).to receive(:command).and_raise(failed_error)

        expect { command.call }.to raise_error(Git::FailedError)
      end
    end

    context 'with unsupported options' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(invalid_option: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :invalid_option/)
        )
      end
    end
  end
end
