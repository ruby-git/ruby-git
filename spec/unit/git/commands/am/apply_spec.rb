# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/am/apply'

RSpec.describe Git::Commands::Am::Apply do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no mbox files' do
      it 'calls git am with no arguments' do
        expected_result = command_result
        expect_command_capturing('am').and_return(expected_result)
        result = command.call
        expect(result).to eq(expected_result)
      end
    end

    context 'with a single mbox file' do
      it 'calls git am with end-of-options separator and the mbox file' do
        expect_command_capturing('am', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox')
      end
    end

    context 'with multiple mbox files' do
      it 'calls git am with all mbox files after --' do
        expect_command_capturing('am', '--', 'a.mbox', 'b.mbox').and_return(command_result)
        command.call('a.mbox', 'b.mbox')
      end
    end

    context 'with :signoff option' do
      it 'adds --signoff flag' do
        expect_command_capturing('am', '--signoff', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', signoff: true)
      end

      it 'accepts :s alias' do
        expect_command_capturing('am', '--signoff', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', s: true)
      end
    end

    context 'with :keep option' do
      it 'adds --keep flag' do
        expect_command_capturing('am', '--keep', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', keep: true)
      end

      it 'accepts :k alias' do
        expect_command_capturing('am', '--keep', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', k: true)
      end
    end

    context 'with :keep_non_patch option' do
      it 'adds --keep-non-patch flag' do
        expect_command_capturing('am', '--keep-non-patch', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', keep_non_patch: true)
      end
    end

    context 'with :keep_cr option' do
      context 'when true' do
        it 'adds --keep-cr flag' do
          expect_command_capturing('am', '--keep-cr', '--', 'patches.mbox').and_return(command_result)
          command.call('patches.mbox', keep_cr: true)
        end
      end

      context 'when false' do
        it 'adds --no-keep-cr flag' do
          expect_command_capturing('am', '--no-keep-cr', '--', 'patches.mbox').and_return(command_result)
          command.call('patches.mbox', keep_cr: false)
        end
      end
    end

    context 'with :scissors option' do
      context 'when true' do
        it 'adds --scissors flag' do
          expect_command_capturing('am', '--scissors', '--', 'patches.mbox').and_return(command_result)
          command.call('patches.mbox', scissors: true)
        end
      end

      context 'when false' do
        it 'adds --no-scissors flag' do
          expect_command_capturing('am', '--no-scissors', '--', 'patches.mbox').and_return(command_result)
          command.call('patches.mbox', scissors: false)
        end
      end

      it 'accepts :c alias' do
        expect_command_capturing('am', '--scissors', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', c: true)
      end
    end

    context 'with :message_id option' do
      context 'when true' do
        it 'adds --message-id flag' do
          expect_command_capturing('am', '--message-id', '--', 'patches.mbox').and_return(command_result)
          command.call('patches.mbox', message_id: true)
        end
      end

      context 'when false' do
        it 'adds --no-message-id flag' do
          expect_command_capturing('am', '--no-message-id', '--', 'patches.mbox').and_return(command_result)
          command.call('patches.mbox', message_id: false)
        end
      end

      it 'accepts :m alias' do
        expect_command_capturing('am', '--message-id', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', m: true)
      end
    end

    context 'with :quiet option' do
      it 'adds --quiet flag' do
        expect_command_capturing('am', '--quiet', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', quiet: true)
      end

      it 'accepts :q alias' do
        expect_command_capturing('am', '--quiet', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', q: true)
      end
    end

    context 'with :utf8 option' do
      context 'when true' do
        it 'adds --utf8 flag' do
          expect_command_capturing('am', '--utf8', '--', 'patches.mbox').and_return(command_result)
          command.call('patches.mbox', utf8: true)
        end
      end

      context 'when false' do
        it 'adds --no-utf8 flag' do
          expect_command_capturing('am', '--no-utf8', '--', 'patches.mbox').and_return(command_result)
          command.call('patches.mbox', utf8: false)
        end
      end

      it 'accepts :u alias' do
        expect_command_capturing('am', '--utf8', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', u: true)
      end
    end

    context 'with :three_way option' do
      context 'when true' do
        it 'adds --3way flag' do
          expect_command_capturing('am', '--3way', '--', 'patches.mbox').and_return(command_result)
          command.call('patches.mbox', three_way: true)
        end
      end

      context 'when false' do
        it 'adds --no-3way flag' do
          expect_command_capturing('am', '--no-3way', '--', 'patches.mbox').and_return(command_result)
          command.call('patches.mbox', three_way: false)
        end
      end
    end

    context 'with :rerere_autoupdate option' do
      context 'when true' do
        it 'adds --rerere-autoupdate flag' do
          expect_command_capturing('am', '--rerere-autoupdate', '--', 'patches.mbox').and_return(command_result)
          command.call('patches.mbox', rerere_autoupdate: true)
        end
      end

      context 'when false' do
        it 'adds --no-rerere-autoupdate flag' do
          expect_command_capturing('am', '--no-rerere-autoupdate', '--', 'patches.mbox').and_return(command_result)
          command.call('patches.mbox', rerere_autoupdate: false)
        end
      end
    end

    context 'with :ignore_space_change option' do
      it 'adds --ignore-space-change flag' do
        expect_command_capturing('am', '--ignore-space-change', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', ignore_space_change: true)
      end
    end

    context 'with :ignore_whitespace option' do
      it 'adds --ignore-whitespace flag' do
        expect_command_capturing('am', '--ignore-whitespace', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', ignore_whitespace: true)
      end
    end

    context 'with :whitespace option' do
      it 'adds --whitespace <action> flag' do
        expect_command_capturing('am', '--whitespace', 'fix', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', whitespace: 'fix')
      end
    end

    context 'with :C option' do
      it 'adds -C<n> flag inline' do
        expect_command_capturing('am', '-C3', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', C: 3)
      end
    end

    context 'with :p option' do
      it 'adds -p<n> flag inline' do
        expect_command_capturing('am', '-p2', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', p: 2)
      end
    end

    context 'with :directory option' do
      it 'adds --directory flag' do
        expect_command_capturing('am', '--directory', '/some/dir', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', directory: '/some/dir')
      end
    end

    context 'with :exclude option' do
      it 'adds --exclude for a single pattern' do
        expect_command_capturing('am', '--exclude', '*.txt', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', exclude: ['*.txt'])
      end

      it 'repeats --exclude for multiple patterns' do
        expect_command_capturing('am', '--exclude', '*.txt', '--exclude', '*.rb', '--',
                                 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', exclude: ['*.txt', '*.rb'])
      end
    end

    context 'with :include option' do
      it 'adds --include for a single pattern' do
        expect_command_capturing('am', '--include', '*.rb', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', include: ['*.rb'])
      end
    end

    context 'with :reject option' do
      it 'adds --reject flag' do
        expect_command_capturing('am', '--reject', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', reject: true)
      end
    end

    context 'with :patch_format option' do
      it 'adds --patch-format flag' do
        expect_command_capturing('am', '--patch-format', 'mbox', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', patch_format: 'mbox')
      end
    end

    context 'with :committer_date_is_author_date option' do
      it 'adds --committer-date-is-author-date flag' do
        expect_command_capturing('am', '--committer-date-is-author-date', '--',
                                 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', committer_date_is_author_date: true)
      end
    end

    context 'with :ignore_date option' do
      it 'adds --ignore-date flag' do
        expect_command_capturing('am', '--ignore-date', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', ignore_date: true)
      end
    end

    context 'with :gpg_sign option' do
      context 'when true' do
        it 'adds --gpg-sign flag' do
          expect_command_capturing('am', '--gpg-sign', '--', 'patches.mbox').and_return(command_result)
          command.call('patches.mbox', gpg_sign: true)
        end
      end

      context 'when a key ID string' do
        it 'adds --gpg-sign=<key> flag inline' do
          expect_command_capturing('am', '--gpg-sign=ABCDEF01', '--', 'patches.mbox').and_return(command_result)
          command.call('patches.mbox', gpg_sign: 'ABCDEF01')
        end
      end

      context 'when false' do
        it 'adds --no-gpg-sign flag' do
          expect_command_capturing('am', '--no-gpg-sign', '--', 'patches.mbox').and_return(command_result)
          command.call('patches.mbox', gpg_sign: false)
        end
      end

      it 'accepts :S alias' do
        expect_command_capturing('am', '--gpg-sign=ABCDEF01', '--', 'patches.mbox').and_return(command_result)
        command.call('patches.mbox', S: 'ABCDEF01')
      end
    end

    context 'with :chdir execution option' do
      it 'passes chdir to the execution context but not to the git CLI' do
        expect_command_capturing('am', '--', 'patches.mbox', chdir: '/some/dir').and_return(command_result)
        command.call('patches.mbox', chdir: '/some/dir')
      end
    end
  end
end
